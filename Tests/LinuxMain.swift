import XCTest

import RPiTests

var tests = [XCTestCaseEntry]()
tests += RPiTests.allTests()
XCTMain(tests)
