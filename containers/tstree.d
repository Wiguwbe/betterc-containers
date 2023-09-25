/**
  Ternary search tree, associative map
  implementation

  this implements a string -> value map
*/
module containers.tstree;

import core.lifetime;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

///
template tstree(T)
{
  /**
    The tree node
  */
  struct Node
  {
    Node* mid = null;
    Node* left = null;
    Node* right = null;
    char splitchar = '\0';
    bool has_value = false;
    T value;
    alias value this;

    this(char sc, T value)
    {
      splitchar = sc;
      this.value = value;
    }

    this(char sc)
    {
      splitchar = sc;
      this.value = T.init;
    }
  }

  /**
    A string->T node
    useful for insertions
    and initialization
  */
  struct DataNode
  {
    string key;
    T value;
  }

  /**
    The tree head
  */
  struct Tree
  {
    Node* root = null;

    /// initialize with an array of key/values
    this(DataNode[] values)
    {
      foreach(DataNode val; values)
        insert(val.key, val.value);
    }

    /// insert with string
    T* insert(string key, T val)
    {
      return insert(cast(char*)key.ptr, key.length, val);
    }

    /// insert with null-terminated char*
    T* insert(char* key, T val)
    {
      return insert(key, strlen(key), val);
    }

    /// insert with char* and length
    T* insert(char* key, ulong key_len, T val)
    {
      Node* p = root;
      Node* last = root;
      ulong idx = 0;
      while(p)
      {
        last = p;
        if(key[idx] < p.splitchar)
          p = p.left;
        else if(key[idx] > p.splitchar)
          p = p.right;
        else /* key[idx] == p.splitchar */
        {
          if(idx == (key_len-1))
            // already there
            // TODO override?
            return &p.value;
          idx += p.mid ? 1 : 0;
          p = p.mid;
        }
      }

      // p is null now
      p = cast(Node*)malloc(Node.sizeof);
      if(!p)
        return null;

      if(!root)
        root = p;
      else if(last.splitchar > key[idx])
        last.left = p;
      else if(last.splitchar < key[idx])
        last.right = p;
      else
      {
        last.mid = p;
        idx++;
      }

      *p = Node(key[idx]);
      idx++;

      while(idx < key_len)
      {
        p.mid = cast(Node*)malloc(Node.sizeof);
        if(!p)
          return null;
        *p.mid = Node(key[idx]);
        idx++;
        last = p;
        p = p.mid;
      }
      p.value = val;
      p.has_value = true;

      return &p.value;
    }

    /// get with string
    T* get(string key)
    {
      return get(cast(char*)key.ptr, key.length);
    }

    /// get with null-terminated char*
    T* get(char* key)
    {
      return get(key, strlen(key));
    }

    /// get with char* and length
    T* get(char* key, ulong key_len)
    {
      if(!key_len)
        return null;

      Node* p = root;
      ulong idx = 0;

      while(p)
      {
        if(key[idx] < p.splitchar)
          p = p.left;
        if(key[idx] > p.splitchar)
          p = p.right;
        else
        {
          idx++;
          if(idx == key_len)
            return p.has_value ? &p.value : null;
          p = p.mid;
        }
      }

      return null;
    }
  }
}

///
unittest
{
  // try a map string->integer
  
  alias AgeTree = tstree!int;
  alias Tree = AgeTree.Tree;
  alias DN = AgeTree.DataNode;

  // let's try an empty tree
  Tree tree = Tree();
  // insert one
  int* p = tree.insert("5", 5);
  assert(*p == 5);
  assert(tree.root.splitchar == '5');
  assert(tree.root.value == 5);

  // insert another
  p = tree.insert("3", 3);
  assert(*p == 3);
  assert(tree.root.left != null);
  assert(tree.root.left.splitchar == '3');
  assert(tree.root.left.value == 3);

  p = tree.insert("56", 56);
  assert(*p == 56);
  assert(tree.root.mid != null);
  assert(tree.root.mid.splitchar == '6');
  assert(tree.root.mid.value == 56);

  p = tree.get("3");
  assert(p != null);
  assert(*p == 3);

  // unexistent
  p = tree.get("666");
  assert(p == null);

  p = tree.get("56");
  assert(p != null);
  assert(*p == 56);

  // duplicate, keep the last one
  p = tree.insert("56", 57);
  assert(p != null);
  assert(*p == 56);
}

///
unittest
{
  // test with initializers
  
  alias AgeTree = tstree!int;
  alias Tree = AgeTree.Tree;
  alias DN = AgeTree.DataNode;
  int* p;

  Tree tree = Tree([DN("5", 5), DN("3", 3), DN("56", 56)]);

  // same tests as above

  /*
    here we're testing assuming it inserts in order
    which may change in the future
  */
  assert(tree.root.splitchar == '5');
  assert(tree.root.value == 5);
  assert(tree.root.left != null);
  assert(tree.root.left.splitchar == '3');
  assert(tree.root.left.value == 3);
  assert(tree.root.mid != null);
  assert(tree.root.mid.splitchar == '6');
  assert(tree.root.mid.value == 56);

  p = tree.get("3");
  assert(p != null);
  assert(*p == 3);

  // unexistent
  p = tree.get("666");
  assert(p == null);

  p = tree.get("56");
  assert(p != null);
  assert(*p == 56);
}

///
unittest
{
  // "heavy" tests
  
  alias AgeTree = tstree!int;
  alias Tree = AgeTree.Tree;
  alias DN = AgeTree.DataNode;

  Tree tree = Tree([DN("alex", 60), DN("beatrice", 17)]);
  int* p = tree.get("alex");
  assert(p != null);
  assert(*p == 60);

  p = tree.insert("charlie", 29);
  assert(p != null);
  p = tree.insert("duarte", 33);
  assert(p != null);

  // and to complicate things
  p = tree.insert("alexandre", 55);
  assert(p != null);
  p = tree.insert("alexandra", 44);
  assert(p != null);
  p = tree.insert("alexandria", 1923);
  assert(p != null);
  p = tree.insert("alcatraz", 6);
  assert(p != null);

  // and some weird retrievals
  p = tree.get("alexan");
  // the current implementation returns null
  assert(p == null);

  p = tree.get("alex");
  assert(p != null);
  assert(*p == 60);

  p = tree.get("alexandra");
  assert(p != null);
  assert(*p == 44);

  p = tree.get("alcatraz");
  assert(p != null);
  assert(*p == 6);

  // partial match doesn't have value
  p = tree.get("alca");
  assert(p == null);
}
  
