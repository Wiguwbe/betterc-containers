/**
	Single linked-list implementation
*/
module containers.slist;

import core.lifetime;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

///
template slist(T)
{
	/**
		The list node
	*/
	struct Item
	{
	private:
		Item *_next = null;
	public:
		T _value;
		alias _value this;
		@property
		T* value()
		{
			return &_value;
		}
	}

	/**
		A list iterator, allows
		for '++' operation,

		the `val` may be null if reached the end
	*/
	struct Iter
	{
		Item *val;
		alias val this;

		/// moves to next item
		void opUnary(string s : "++")()
		{
			if(val)
				val = val._next;
		}
	}

	/**
		The main structure

		Most of these functions return a pointer to the value,
		or null if an error occured
	*/
	struct List
	{
	private:
		Item *head = null;
		Item *tail = null;
		size_t _size = 0;

	public:
		~this()
		{
			Item *ptr;
			while(head)
			{
				ptr = head._next;
				destroy(head);
				free(head);
				head = ptr;
			}
		}

		
		/// Put an empty item at `index`
		/**
			Examples:
			---
			ptr = list.put(3);
			ptr.property = some_value;
			---
		*/
		T* put(int index)
		{
			if(index<0||index >= _size)
				return null;

			Item* ptr = cast(Item*)malloc(Item.sizeof);
			if(!ptr)
				return null;
			emplace(ptr);

			// put after 'item'
			Item pre_head;
			pre_head._next = head;
			Item* item = &pre_head;
			while(index--)
				item = item._next;

			ptr._next = item._next;
			item._next = ptr;
			head = pre_head._next;
			_size++;

			return ptr.value;
		}

		/// put a value at `index`
		/**
			Examples:
			---
			list.put(2, Item(property1, property2));
			---
		*/
		T* put(int index, T value)
		{
			T* ptr = put(index);
			if(!ptr)
				return null;
			memcpy(ptr, &value, T.sizeof);
			return ptr;
		}

		/// append an unitialized item to the list
		T* append()
		{
			Item* ptr = cast(Item*)malloc(Item.sizeof);
			if(!ptr)
				return null;
			emplace(ptr);
			ptr._next = null;

			if(!tail)
				head = ptr;
			else
				tail._next = ptr;
			tail = ptr;
			_size++;
			return ptr.value;
		}

		/// prepend an unitialized value to the list, alias to `put(0)`
		T* prepend()
		{
			return put(0);
		}

		/// append a value to the list
		T* append(T value)
		{
			T* ptr = append();
			if(!ptr)
				return null;
			memcpy(ptr, &value, T.sizeof);
			return ptr;
		}

		/// prepend a value to the list
		T* prepend(T value)
		{
			return put(0, value);
		}

		/// get the value at the index
		T* get(int index)
		{
			if(index<0||index >= _size)
				return null;

			Item* ptr = head;
			while(index--)
				ptr = ptr._next;
			return ptr.value;
		}

		/// set a value by reference
		/**
			Examples:
			---
			ptr = list.get(0);
			list.set(4, ptr);
			---
		*/
		T* set(int index, T* value)
		{
			T* ptr = get(index);
			if(!ptr)
				return null;
			memcpy(ptr, value, T.sizeof);
			return ptr;
		}

		/// set a value by value
		T* set(int index, T value)
		{
			return set(index, &value);
		}

		/// delete item at index (memory is also freed)
		void del(int index)
		{
			if(index < 0 || index >= _size)
				return;

			Item pre_head;
			pre_head._next = head;

			Item* ptr = &pre_head;
			while(index--)
				ptr = ptr._next;

			Item* ptr2 = ptr._next;
			ptr._next = ptr._next._next;

			if(ptr2 == tail)
				tail = ptr;
			head = pre_head._next;

			destroy(ptr2);
			free(ptr2);

			_size--;
		}

		/// get an iterator at `head`
		Iter iter()
		{
			return Iter(head);
		}

		// operator overloading

		/// same as `get`
		T* opIndex(int index)
		{
			return get(index);
		}

		/// same as `set`
		T* opIndexAssign(T value, int index)
		{
			return set(index, value);
		}

		/// same as `set`
		T* opIndexAssign(T* value, int index)
		{
			return set(index, value);
		}

		/// utility to get the size of the list
		@property
		size_t size()
		{
			return _size;
		}
	}
}

///
unittest
{
	struct Item
	{
		string name;
		int age;
	}

	alias Items = slist!Item;

	Items.List list;
	Item* ptr;

	// first insert
	ptr = list.append(Item("Alpha", 10));
	assert(ptr != null);	// this can just be an error
	assert(ptr.age == 10);
	assert(ptr.name == "Alpha");
	assert(list.size == 1);	// property

	// append empty
	ptr = list.append();
	assert(ptr != null);
	assert(list.size == 2);
	ptr.name = "Bravo";
	ptr.age = 16;

	// put
	ptr = list.put(1, Item("Charlie", 77));
	assert(ptr != null);
	assert(list.size == 3);
	assert(ptr.name == "Charlie");
	assert(ptr.age == 77);

	// get/index
	assert(list[1] == ptr);

	// set/indexAssign
	list[0] = Item("Delta", 23);
	// duplicate first
	list[2] = list[0];
	// just to diferentiate
	list[2].age = 24;


	// iter and check
	Items.Iter it = list.iter();

	assert(it.name == "Delta");
	assert(it.age == 23);

	it++;

	assert(it.name == "Charlie");
	assert(it.age == 77);

	it++;

	assert(it.name == "Delta");
	assert(it.age == 24);

	it++;

	// the internal state
	assert(it.val == null);

	list.del(0);

	assert(list[0].name == "Charlie");
	assert(list[1].age == 24);

	assert(list.size == 2);

	// it's just an alias to put(0)
	ptr = list.prepend(Item("Echo", 2));
	assert(list.size == 3);
	assert(ptr.name == "Echo");
	assert(ptr.age == 2);
	assert(list[0] == ptr);
}
