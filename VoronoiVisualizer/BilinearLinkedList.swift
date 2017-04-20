//
//  BilinearLinkedList.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/19/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa

open class BilinearSortedLinkedList<T> {

    private class Node<T> {
        let value:T
        var nextX:Node<T>? = nil {
            didSet {
                oldValue?.previousX = nil
                self.nextX?.previousX = self
            }
        }
        var nextY:Node<T>? = nil {
            didSet {
                oldValue?.previousY = nil
                self.nextY?.previousY = self
            }
        }
        weak var previousX:Node<T>? = nil
        weak var previousY:Node<T>? = nil
        
        init(value:T) {
            self.value = value
        }
    }
    
    private var head:Node<T>? = nil
    public let xComparator:(T, T) -> Int
    public let yComparator:(T, T) -> Int
    
    public init(xComparator:@escaping (T, T) -> Int, yComparator:@escaping (T, T) -> Int) {
        self.xComparator = xComparator
        self.yComparator = yComparator
    }
    
    open func add(element:T) {
        guard let head = self.head else {
            self.head = Node(value: element)
            return
        }
        var xNode:Node<T>? = head
        while let currentNode = xNode {
            let comparison = self.xComparator(element, currentNode.value)
            if comparison < 0 {
                //The list is sorted, so we know this
                //is the right place for it.
                let oldNextX = currentNode.nextX
                currentNode.nextX = Node(value: element)
                currentNode.nextX?.nextX = oldNextX
                return
            } else if comparison > 0 {
                //Haven't yet found the correct spot
                //for the new element, keep searching.
                xNode = currentNode.nextX
            } else {
                //If they're equal, we have to start walking the
                //y part of the list.
                break
            }
        }
        
        var yNode:Node<T>? = xNode
        while let currentNode = yNode {
            let comparison = self.yComparator(element, currentNode.value)
            if comparison < 0 {
                //The list is sorted, so we know this
                //is the right place for it.
                let oldNextY = currentNode.nextY
                currentNode.nextY = Node(value: element)
                currentNode.nextY?.nextY = oldNextY
                return
            } else if comparison > 0 {
                //Haven't yet found the correct spot
                //for the new element, keep searching.
                yNode = currentNode.nextY
            } else {
                //Equal values. Will probably throw
                //an exception or something.
                break
            }
        }
    }
    
}
