#!/usr/bin/env python3
"""
Test script for PlayStation metadata fetcher.
"""

import json
import sys
import os

# Add the current directory to Python path to import playstation module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from playstation import PlayStationMetadataFetcher, main


def test_next_data_extraction():
    """Test __NEXT_DATA__ extraction functionality."""
    print("Testing __NEXT_DATA__ extraction...")
    
    # Mock HTML content with __NEXT_DATA__ 
    mock_html = '''
    <html>
    <head>
        <script id="__NEXT_DATA__" type="application/json">
        {
            "props": {
                "pageProps": {
                    "productRetrieve": {
                        "id": "TEST123",
                        "name": "Test Game",
                        "description": "A test game description",
                        "releaseDate": "2023-01-01"
                    }
                }
            }
        }
        </script>
    </head>
    <body></body>
    </html>
    '''
    
    fetcher = PlayStationMetadataFetcher()
    next_data = fetcher._extract_next_data(mock_html)
    
    if next_data:
        print("✓ __NEXT_DATA__ extraction successful")
        print(f"  Found data: {json.dumps(next_data, indent=2)}")
    else:
        print("✗ __NEXT_DATA__ extraction failed")
    
    return next_data is not None


def test_json_ld_extraction():
    """Test JSON-LD extraction functionality."""
    print("\nTesting JSON-LD extraction...")
    
    # Mock HTML content with JSON-LD
    mock_html = '''
    <html>
    <head>
        <script type="application/ld+json">
        {
            "@context": "https://schema.org",
            "@type": "VideoGame",
            "name": "Test Game",
            "description": "A test game",
            "applicationCategory": "Game"
        }
        </script>
    </head>
    <body></body>
    </html>
    '''
    
    fetcher = PlayStationMetadataFetcher()
    json_ld = fetcher._extract_json_ld(mock_html)
    
    if json_ld:
        print("✓ JSON-LD extraction successful")
        print(f"  Found data: {json.dumps(json_ld, indent=2)}")
    else:
        print("✗ JSON-LD extraction failed")
    
    return json_ld is not None


def test_script_execution():
    """Test that the script can be executed with command line args."""
    print("\nTesting script execution...")
    
    try:
        # Test with a dummy content ID
        result = main("TEST123")
        print("✓ Script execution successful")
        print(f"  Result keys: {list(result.keys())}")
        return True
    except Exception as e:
        print(f"✗ Script execution failed: {e}")
        return False


def main_test():
    """Run all tests."""
    print("Running PlayStation metadata fetcher tests...\n")
    
    tests = [
        test_next_data_extraction,
        test_json_ld_extraction, 
        test_script_execution
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
    
    print(f"\nTest Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("All tests passed! ✓")
        return True
    else:
        print("Some tests failed! ✗")
        return False


if __name__ == "__main__":
    success = main_test()
    sys.exit(0 if success else 1)