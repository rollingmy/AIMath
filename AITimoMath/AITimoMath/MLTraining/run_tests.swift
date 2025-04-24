import Foundation

// This file serves as an entry point to run all ML model tests.
// The actual test runner is defined in test_ai_models.swift
// Simply forward the call to MLTestRunner.runAllTests()

func runAllMLTests() {
    print("Starting ML tests from run_tests.swift...")
    MLTestRunner.runAllTests()
    print("All ML tests completed successfully!")
}

// No top-level expressions here 