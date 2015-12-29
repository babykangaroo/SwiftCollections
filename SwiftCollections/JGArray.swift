//
//  JGArray.swift
//  SwiftCollections
//
//  Created by Joey Green on 12/29/15.
//  Copyright © 2015 Joey Green. All rights reserved.
//

import Foundation

struct JGArray<T> : CollectionType {
    //Arrays in swift are value types which means that we copy the contents of the collection on assign. Struct doesn't have construct and desctruct capabilities so we create a class for the actual implementation
    var impl : JGArrayImpl<T> = JGArrayImpl<T>()
    
    //typealias Generator = GeneratorOf<T>// this is so we can use a for loop
    typealias Generator = AnyGenerator<T>// this is so we can use a for loop
    typealias Index = Int
    mutating func append(value: T) {
        ensureUnique()
        impl.append(value)
    }
    
    mutating func ensureUnique() {
        if !isUniquelyReferencedNonObjC(&impl) {
            impl = impl.copy()
        }
    }
    
    //we should do a range check
    mutating func remove(index: Int) {
        ensureUnique()
        impl.remove(index)
    }
    
    var count: Int {
        return impl.count
    }
    
    //we should do a range check
    subscript(index: Int) -> T {
        get {
            return impl.ptr[index]
        }
        mutating set {
            ensureUnique()
            impl.ptr[index] = newValue
        }
    }
    
    var startIndex: Index {
        return 0
    }
    
    var endIndex: Index {
        return count
    }
    
//    func generate() -> Generator {
//        var index = 0
//        return GeneratorOf<T>({
//            if index < self.count {
//                return self[index++]
//            } else {
//                return nil
//            }
//        })
//    }
    
//    func generate() -> Generator {
//        var index = 0
//        return AnyGenerator<T>({
//            if index < self.count {
//                return self[index++]
//            } else {
//                return nil
//            }
//        })
//    }
    func generate() -> Generator {
        var index = 0
        return AnyGenerator<T>{
            if index < self.count {
                return self[index++]
            } else {
                return nil
            }
        }
    }
}

class JGArrayImpl<T> {
    
    var count : Int
    var space : Int
    var ptr : UnsafeMutablePointer<T>
    
    init(count: Int = 0, ptr: UnsafeMutablePointer<T> = nil) {
        self.count = count
        self.space = count
        
        self.ptr = UnsafeMutablePointer<T>.alloc(count)
        self.ptr.initializeFrom(ptr, count: count)
    }
    
    deinit {
        ptr.destroy(count)
        ptr.dealloc(space)
    }
    
    func copy() -> JGArrayImpl<T> {
        return JGArrayImpl<T>(count: count, ptr: ptr)
    }
    
    func append(obj: T)
    {
       //My mental model
       //Add a new element to the end of the current array. This means either reallocating memory or already reserving a big enough buffer for new elements
       //Also how do we know the size of the buffer for each element. Will we allow anything to be saved ( Um, no ). We need to know the type of elements the array will hold so we can allocated the currect buffer size. This is handle
       //by providing T to UnsafeMutablePointer.
        
        if space == count{
            let newSpace = max(space * 2, 16)//16 is the floor so if space * 2 is greater than 16 then we will just return 16
            let newPtr = UnsafeMutablePointer<T>.alloc(newSpace)// allocate more space
            newPtr.moveInitializeFrom(ptr, count: count)//copy old data to new location
            ptr.dealloc(space)
            ptr = newPtr
            space = newSpace
        }
        //copy the new value into the end of the memory
        (ptr + count).initialize(obj)//ptr + count I believe would be memory math
        count++
    }
    
    func remove(index: Int) {
        var ptr2 = ptr + index
        (ptr + index).destroy()//destroy the value being removed
        (ptr + index).moveInitializeFrom(ptr + index + 1, count: count - index - 1)//takes care of shuffling all remaining items down by one
        count--
    }
}