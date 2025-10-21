//
//  TranscriberModel.swift
//  unmute
//
//  Created by Wentao Guo on 21/10/25.
//


class TranscriberModel {
    var textLines: [String] = []
    var speakers: [String] = []
    
    func add(_ item: [String: String]) {
        textLines.append(item["text"]!)
        speakers.append(item["speaker"]!)
    }
    
}
