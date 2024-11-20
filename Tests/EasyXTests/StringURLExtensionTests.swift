//
//  File.swift
//  
//
//  Created by Shahanul Haque on 9/1/24.
//
import XCTest
import Foundation
import XCTest


@testable import EasyX

class URLUtilsTests: XCTestCase {
    
    func testIsWebURL() {
        XCTAssertTrue("https://www.example.com".isWebURL)
        XCTAssertTrue("http://www.example.com".isWebURL)
        XCTAssertFalse("ftp://www.example.com".isWebURL)
        XCTAssertFalse("www.example.com".isWebURL)
        XCTAssertFalse("".isWebURL)
    }
    
    func testToWebURL() {
        XCTAssertEqual("https://www.example.com".toWebURL, URL(string: "https://www.example.com"))
        XCTAssertEqual("http://www.example.com".toWebURL, URL(string: "http://www.example.com"))
        XCTAssertNil("ftp://www.example.com".toWebURL)
        XCTAssertNil("invalid-url".toWebURL)
    }
    
    func testWebUrlString() {
        XCTAssertEqual("https://www.example.com".webUrlString, "https://www.example.com")
        XCTAssertEqual("http://www.example.com".webUrlString, "http://www.example.com")
        XCTAssertNil("ftp://www.example.com".webUrlString)
        XCTAssertNil("invalid-url".webUrlString)
        XCTAssertNil("".webUrlString)
        XCTAssertNil("gg".webUrlString)
    }
    func testMimeTypeForKnownExtensions() {
            let jpegUrl = "file://example.com/image.jpg"
            XCTAssertEqual(jpegUrl.mimeType(), "image/jpeg")

            let pngUrl = "file://example.com/image.png"
            XCTAssertEqual(pngUrl.mimeType(), "image/png")

            let pdfUrl = "file://example.com/document.pdf"
            XCTAssertEqual(pdfUrl.mimeType(), "application/pdf")
        }

        func testMimeTypeForUnknownExtension() {
            let unknownUrl = "file://example.com/file.unknown"
            XCTAssertEqual(unknownUrl.mimeType(), "application/octet-stream")
        }

        func testMimeTypeForNoExtension() {
            let noExtensionUrl = "file://example.com/file"
            XCTAssertEqual(noExtensionUrl.mimeType(), "application/octet-stream")
        }
    func testMimeTypeForWebURL() {
            let webUrl = "http://192.168.11.200:9000/decoraan/product/4885028965223058124-Avatar.png"
            XCTAssertEqual(webUrl.mimeType(), "image/png")
        }

}
