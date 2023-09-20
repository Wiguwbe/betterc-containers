/**
	Double linked-list implementation
*/
module containers.dlist;

import core.lifetime;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

///
template dlist(T)
{
	/// The list node
	struct Item
	{
	private:
		Item* _next = null;
		Item* _prev = null;
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
		to move forward ('++') and backwards ('--'),

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
		/// moves to previous item
		void opUnary(string s : "--")()
		{
			if(val)
				val = val._prev;
		}
	}

	/**
		The main structure

		Most of these functions return a pointer to the value,
		or null if an error occured.

		As a double linked-list, indexes provided may be negative
		(count from tail, -1 is last)
	*/
	struct List
	{
	private:
		Item *_head = null;
		Item *_tail = null;
		size_t _size = 0;

	public:
		~this()
		{
			Item *ptr;
			while(_head)
			{
				ptr = _head._next;
				destroy(_head);
				free(_head);
				_head = ptr;
			}
		}

		/// put an empty item at `index`
		T* put(int index)
		{
			if(index >= 0 && index >= _size)
				return null;

			if(index < 0 && (-index) > _size)
				return null;

			Item* ptr = cast(Item*)malloc(Item.sizeof);
			if(!ptr)
				return null;
			emplace(ptr);

			// put before 'item'
			Item* item;
			if(index >= 0)
			{
				item = _head;
				while(index--)
					item = item._next;
			}
			else
			{
				item = _tail;
				while(++index)
					item = item._prev;
			}

			ptr._prev = item._prev;
			item._prev = ptr;
			ptr._next = item;
			if(ptr._prev)
				ptr._prev._next = ptr;
			else
				_head = ptr;

			_size++;

			return ptr.value;
		}

		/// put `value` at `index`
		T* put(int index, T value)
		{
			T* ptr = put(index);
			if(!ptr)
				return null;
			memcpy(ptr, &value, T.sizeof);
			return ptr;
		}

		/// append an unitialized value to the list
		T* append()
		{
			Item *ptr = cast(Item*)malloc(Item.sizeof);
			if(!ptr)
				return null;
			emplace(ptr);

			if(!_tail)
				_head = ptr;
			else
				_tail._next = ptr;

			ptr._prev = _tail;
			_tail = ptr;
			_size++;
			return ptr.value;
		}

		/// prepend to the list, alias to `put(0)`
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

		/// prepend a value to the list, alias to `put(0, value)`
		T* prepend(T value)
		{
			return put(0, value);
		}

		/// get value by index
		T* get(int index)
		{
			Item *ptr;
			if(index < 0)
			{
				if((-index) > _size)
					return null;
				ptr = _tail;
				while(++index)
					ptr = ptr._prev;
			}
			else
			{
				if(index >= _size)
					return null;
				ptr = _head;
				while(index--)
					ptr = ptr._next;
			}
			return ptr.value;
		}

		/// set value at index, by reference
		T* set(int index, T* value)
		{
			T* ptr = get(index);
			if(!ptr)
				return null;
			memcpy(ptr, value, T.sizeof);
			return ptr;
		}

		/// set value at index, by value
		T* set(int index, T value)
		{
			return set(index, &value);
		}

		/// delete item at index
		void del(int index)
		{
			Item *ptr;
			if(index < 0)
			{
				if((-index) > _size)
					return;
				ptr = _tail;
				while(++index)
					ptr = ptr._prev;
			}
			else
			{
				if(index >= _size)
					return;
				ptr = _head;
				while(index--)
					ptr = ptr._next;
			}
			// delete
			if(ptr._prev)
				ptr._prev._next = ptr._next;
			else
				_head = ptr._next;
			if(ptr._next)
				ptr._next._prev = ptr._prev;
			else
				_tail = ptr._prev;

			destroy(ptr);
			free(ptr);
			_size--;
		}

		/// get an iterator at `head`
		Iter iter()
		{
			return Iter(_head);
		}

		/// get an iterator at `tail`
		Iter iter_rev()
		{
			return Iter(_tail);
		}

		// operators and properties

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

		/// ditto
		T* opIndexAssign(T*value, int index)
		{
			return set(index, value);
		}

		/// get size of list
		@property
		size_t size()
		{
			return _size;
		}

		/// iterator at `head`
		@property
		Iter head()
		{
			return iter();
		}

		/// iterator at `tail`
		@property
		Iter tail()
		{
			return iter_rev();
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

	alias Items = dlist!Item;

	Items.List list;
	Item* ptr;

	assert(list.size == 0);

	ptr = list.append(Item("Alpha", 10));
	assert(ptr != null);
	assert(list.size == 1);
	assert(ptr.name == "Alpha");
	assert(ptr.age == 10);
	assert(list[0] == ptr);

	ptr = list.prepend(Item("Bravo", 20));
	assert(ptr != null);
	assert(list.size == 2);
	assert(ptr.name == "Bravo");
	assert(ptr.age == 20);
	assert(list[0] == ptr);

	ptr = list.put(1, Item("Charlie", 14));
	assert(ptr != null);
	assert(list.size == 3);
	assert(ptr.name == "Charlie");
	assert(ptr.age == 14);
	assert(list[1] == ptr);

	// interlude
	assert(list[0].age == 20);
	assert(list[2].age == 10);

	// negative indexes
	ptr = list.put(-1, Item("Delta", 33));
	assert(ptr != null);
	assert(list.size == 4);
	assert(ptr.name == "Delta");
	assert(ptr.age == 33);
	assert(list[2] == ptr);
	assert(list[3].age == 10);
	assert(list[1].age == 14);

	assert(list[-1].age == 10);
	assert(list[-2].age == 33);
	assert(list[-3].age == 14);
	assert(list[-4].age == 20);

	// out of range
	assert(list[10] == null);
	assert(list[-5] == null);

	// del pos/neg
	list.del(0);
	list.del(-3);	// -3 == 0

	assert(list.size == 2);

	// iterators
	Items.Iter it;

	it = list.head;
	assert(it.name == "Delta");
	assert(it.age == 33);
	it++;
	assert(it.name == "Alpha");
	assert(it.age == 10);
	it++;
	assert(it.val == null);

	// reverse
	it = list.tail;
	assert(it.name == "Alpha");
	it--;
	assert(it.name == "Delta");
	// they should be reversible
	it++;
	assert(it.name == "Alpha");

	// prepend, alias to put(0)
	ptr = list.prepend(Item("Echo", 44));
	assert(list.size == 3);
	assert(list[0] == ptr);

	// set
	list[0] = Item("Fox", 89);
	assert(list[0].name == "Fox");
	assert(list[0].age == 89);

	// delete all
	list.del(1);
	list.del(-2);
	list.del(0);
	assert(list.size == 0);
}
