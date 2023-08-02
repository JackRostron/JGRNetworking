//
//  MultipartForm.swift
//  
//
//  Created by Jack Rostron on 02/08/2023.
//

import Foundation

public struct MultipartForm {
    public var data: Data
    public var fieldName: String
    public var fileName: String
    public var mimeType: String
    
    public init(data: Data, fieldName: String, fileName: String, mimeType: String) {
        self.data = data
        self.fieldName = fieldName
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
