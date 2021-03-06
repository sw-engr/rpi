﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading; // for AutoResetEvent

namespace VisualCompiler
{
    // See CircularQueue.  This class not tried.
    public class CircularBuffer<T> //: ICircularBuffer<T>, IEnumerable<T>
    {
        // From "Circular Buffer in C#" post of Rob Blackbourn, with removal of 
        // ICircularBuffer<T> and IEnumerable<T>

        private T[] _buffer;
		private int _head;
		private int _tail;

        public CircularBuffer(int capacity) // constructor
		{
			if (capacity < 0)
				throw new ArgumentOutOfRangeException ("capacity", "must be positive");
			_buffer = new T[capacity];
			_head = capacity - 1;
		} // end constructor

        public int Count { get; private set; }

        public int Capacity
        {
            get { return _buffer.Length; }
            set
            {
                if (value < 0)
                    throw new ArgumentOutOfRangeException("value", "must be positive");

                if (value == _buffer.Length)
                    return;

                var buffer = new T[value];
                var count = 0;
                while (Count > 0 && count < value)
                    buffer[count++] = Dequeue();

                _buffer = buffer;
                Count = count;
                _head = count - 1;
                _tail = 0;
            }
        }

        public T Enqueue(T item)
        {
            _head = (_head + 1) % Capacity;
            var overwritten = _buffer[_head];
            _buffer[_head] = item;
            if (Count == Capacity)
                _tail = (_tail + 1) % Capacity;
            else
                ++Count;
            return overwritten;
        }

        public T Dequeue()
        {
            if (Count == 0)
                throw new InvalidOperationException("queue exhausted");

            var dequeued = _buffer[_tail];
            _buffer[_tail] = default(T);
            _tail = (_tail + 1) % Capacity;
            --Count;
            return dequeued;
        }

        public void Clear()
        {
            _head = Capacity - 1;
            _tail = 0;
            Count = 0;
        }

        public T this[int index]
        {
            get
            {
                if (index < 0 || index >= Count)
                    throw new ArgumentOutOfRangeException("index");

                return _buffer[(_tail + index) % Capacity];
            }
            set
            {
                if (index < 0 || index >= Count)
                    throw new ArgumentOutOfRangeException("index");

                _buffer[(_tail + index) % Capacity] = value;
            }
        }

        public int IndexOf(T item)
        {
            for (var i = 0; i < Count; ++i)
                if (Equals(item, this[i]))
                    return i;
            return -1;
        }

        public void Insert(int index, T item)
        {
            if (index < 0 || index > Count)
                throw new ArgumentOutOfRangeException("index");

            if (Count == index)
                Enqueue(item);
            else
            {
                var last = this[Count - 1];
                for (var i = index; i < Count - 2; ++i)
                    this[i + 1] = this[i];
                this[index] = item;
                Enqueue(last);
            }
        }

        public void RemoveAt(int index)
        {
            if (index < 0 || index >= Count)
                throw new ArgumentOutOfRangeException("index");

            for (var i = index; i > 0; --i)
                this[i] = this[i - 1];
            Dequeue();
        }

        public IEnumerator<T> GetEnumerator()
        {
            if (Count == 0 || Capacity == 0)
                yield break;

            for (var i = 0; i < Count; ++i)
                yield return this[i];
        }

    } // end class CircularBuffer<T>

    public class CircularQueue
    {
        // Queued items will be removed from the queue as they are read.
        public struct QueueDataType // Queued topic messages
        {
            public byte[] message;
        };

        int size = 30;
        private class QueueType
        {
            public bool unread; 
            public int nextReadIndex;
            public int nextWriteIndex;
            public QueueDataType[] list = new QueueDataType[30]; // i.e., size
        };

        private QueueType queue = new QueueType();

        private Object queueLock = new Object();

        private int remoteAppId;

        private byte[] none = new byte[0];

        private ReceiveInterface receiveInterface;

        public CircularQueue(int appId) // constructor
        {
            remoteAppId = appId;
            queue.unread = false;
            queue.nextReadIndex = 0;
            queue.nextWriteIndex = 0;

        } // end constructor

        public void SupplyReceiveInterface(ReceiveInterface classInstance)
        {
            receiveInterface = classInstance;
        } // end SupplyReceiveInterface

        // Clear the queue if case don't want to instantiate the queue again
        public void Clear()
        {
            queue.unread = false;
            queue.nextReadIndex = 0;
            queue.nextWriteIndex = 0;
        } // end Clear

        public byte[] Read()
        {
            bool rtnNone;
            int savedReadIndex;
            lock (queueLock)
            {
                rtnNone = false;
                if (queue.nextReadIndex == queue.nextWriteIndex)
                {
                    ConsoleOut.WriteLine("CircularQueue NRI == nWI");
                    queue.unread = false;
                    rtnNone = true;
                }
                savedReadIndex = queue.nextReadIndex;
                if ((queue.nextReadIndex+1) >= size)
                {
                    queue.nextReadIndex = 0;
                }
                else
                {
                    queue.nextReadIndex++;
                }
                if (queue.nextReadIndex == queue.nextWriteIndex)
                {
                    queue.unread = false;
                }
                else
                {
                    queue.unread = true;
                }
            } // end lock
            if (rtnNone)
            {
                return none;
            }
            else
            {
                return queue.list[savedReadIndex].message;
            }
        } // end Read

        public bool Unread()
        {
            return queue.unread;
        } // end Unread

        public bool Write(byte[] message)
        {
            bool rtn = true;

            lock (queueLock)
            {
                int currentIndex = queue.nextWriteIndex;
                int nextIndex = currentIndex + 1;
                if ((nextIndex) >= size)
                {
                    nextIndex = 0;
                }
                if (nextIndex == queue.nextReadIndex)
                { // queue overrun
                    ConsoleOut.WriteLine("ERROR: CircularQueue overrun");
                    rtn = false;
                }
                if (rtn)
                {
                    queue.list[currentIndex].message = message;
                    queue.nextWriteIndex = nextIndex;
                    queue.unread = true;
                }
            }
            receiveInterface.Signal(); // signal wakeup to ReceiveInterface
            return rtn;
        } // end Write

    } // end class CircularQueue
    
} // end namespace
