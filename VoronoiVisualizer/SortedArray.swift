//
//  SortedArray.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/17/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa

func binarySearch<T>(for value:T, in array:[T], comparator:(T, T) -> Int) -> Int {
    var l = 0
    var r = array.count - 1
    var m = 0
    while l <= r {
        m = (l + r) / 2
        let result = comparator(array[m], value)
        if result < 0 {
            l = m + 1
        } else if result > 0 {
            r = m - 1
        } else {
            return m
        }
    }
    return m
}

public struct SortedArray<T>: Sequence {
    
    public typealias Iterator = IndexingIterator<[T]>
    
    private let comparator:(T, T) -> Int
    private var elements:[T] = []
    public var count:Int { return self.elements.count }
    
    public init(comparator:@escaping (T, T) -> Int) {
        self.comparator = comparator
    }
    
    public init(elements:[T], comparator:@escaping (T, T) -> Int) {
        self.comparator = comparator
        for element in elements {
            self.add(element: element)
        }
    }
    
    public subscript(index:Int) -> T {
        get {
            return self.elements[index]
        }
        set {
            self.elements[index] = newValue
        }
    }
    
    public mutating func add(element:T) {
        let index = binarySearch(for: element, in: self.elements, comparator: self.comparator)
        if self.count > 0 && self.comparator(self[index], element) < 0 {
            self.elements.insert(element, at: index + 1)
        } else {
            self.elements.insert(element, at: index)
        }
    }
    
    public mutating func remove(at index:Int) -> T? {
        if index < 0 || index >= self.count {
            return nil
        }
        return self.elements.remove(at: index)
    }
    
    public func indices(adjacentTo element:T) -> (Int, Int) {
        let index = binarySearch(for: element, in: self.elements, comparator: self.comparator)
        let result = self.comparator(self[index], element)
        if result < 0 {
            return (index, index + 1)
        } else if (result > 0) {
            return (index - 1, index)
        } else {
            return (index, index)
        }
    }
    
    public func makeIterator() -> Iterator {
        return self.elements.makeIterator()
    }
    
}
