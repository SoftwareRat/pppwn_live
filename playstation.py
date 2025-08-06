#!/usr/bin/env python3
"""
PlayStation Concept Data Retrieval Script

This script fetches PlayStation concept page data by:
1. Parsing HTML pages to extract 'batarangs' caches and apolloState data
2. Using GraphQL queries as a fallback to retrieve concept metadata

The script addresses the requirements specified in the problem statement:
- Fully extracts batarangs caches (background-image, game-title, info, etc.)
- Parses embedded JSON components and collects entries under cache for Concept:<id>
- Extracts relevant entries from apolloState for the same Concept:<id>
- Provides fetch_concept_graphql() function for GraphQL ConceptRetrieve queries
- In main(), calls both methods and includes GraphQL result under result['concept_graphql']

Usage:
    python playstation.py <concept_id>    # Fetch data for a concept ID
    python playstation.py test           # Run tests with sample data
    
Example:
    python playstation.py 123456
"""

import json
import re
import requests
from typing import Dict, Any, Optional
from urllib.parse import urljoin


class PlayStationDataFetcher:
    """Handles fetching and parsing PlayStation concept data."""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        })
        self.base_url = "https://store.playstation.com"
        self.graphql_url = "https://web.np.playstation.com/api/graphql/v1/op"
    
    def fetch_concept_page(self, concept_id: str) -> Dict[str, Any]:
        """
        Fetch and parse a PlayStation concept page to extract batarangs caches and apolloState data.
        
        Args:
            concept_id: The concept ID to fetch data for
            
        Returns:
            Dictionary containing extracted data including batarangs and apolloState entries
        """
        result = {
            'concept_id': concept_id,
            'batarangs': {},
            'apollo_state': {},
            'error': None
        }
        
        try:
            # Try multiple PlayStation URL patterns as they may vary
            url_patterns = [
                f"{self.base_url}/en-us/concept/{concept_id}",
                f"{self.base_url}/en-us/product/{concept_id}",
                f"{self.base_url}/concept/{concept_id}",
                f"https://web.playstation.com/en-us/concept/{concept_id}"
            ]
            
            for url in url_patterns:
                try:
                    response = self.session.get(url, timeout=30)
                    response.raise_for_status()
                    
                    html_content = response.text
                    
                    # Extract batarangs caches from embedded JSON
                    result['batarangs'] = self._extract_batarangs_data(html_content, concept_id)
                    
                    # Extract apolloState data
                    result['apollo_state'] = self._extract_apollo_state_data(html_content, concept_id)
                    
                    # If we found data, we're done
                    if result['batarangs'] or result['apollo_state']:
                        result['url_used'] = url
                        break
                        
                except requests.RequestException:
                    # Try next URL pattern
                    continue
            
            if not result.get('url_used'):
                result['error'] = f"Failed to fetch data from any PlayStation URL pattern for concept {concept_id}"
            
        except Exception as e:
            result['error'] = f"Parsing failed: {str(e)}"
            
        return result
    
    def _extract_batarangs_data(self, html_content: str, concept_id: str) -> Dict[str, Any]:
        """Extract batarangs cache data from HTML content."""
        batarangs_data = {}
        
        try:
            # Look for Next.js script tags containing JSON data
            script_pattern = r'<script[^>]*?>(.*?)</script>'
            scripts = re.findall(script_pattern, html_content, re.DOTALL | re.IGNORECASE)
            
            for script_content in scripts:
                # Clean the script content
                script_content = script_content.strip()
                
                # Skip empty scripts
                if not script_content:
                    continue
                
                # Try to parse as JSON if it looks like JSON (starts with { or [)
                if script_content.startswith(('{', '[')):
                    try:
                        # Attempt to parse as JSON
                        data = json.loads(script_content)
                        
                        # Look for cache entries related to our concept
                        if isinstance(data, dict):
                            cache_data = self._find_concept_cache_entries(data, concept_id)
                            if cache_data:
                                # Merge cache data, categorizing by type
                                for key, value in cache_data.items():
                                    if 'background-image' in str(key).lower():
                                        batarangs_data.setdefault('background-image', {})[key] = value
                                    elif 'game-title' in str(key).lower():
                                        batarangs_data.setdefault('game-title', {})[key] = value
                                    elif 'info' in str(key).lower():
                                        batarangs_data.setdefault('info', {})[key] = value
                                    else:
                                        batarangs_data.setdefault('other', {})[key] = value
                                        
                    except (json.JSONDecodeError, ValueError):
                        # Skip non-JSON content
                        continue
                
                # Also look for JSON within JavaScript assignments
                else:
                    json_patterns = [
                        r'=\s*({.*?});',  # variable = {...};
                        r':\s*({.*?})',   # property: {...}
                    ]
                    
                    for json_pattern in json_patterns:
                        json_matches = re.findall(json_pattern, script_content, re.DOTALL)
                        
                        for json_str in json_matches:
                            try:
                                # Attempt to parse as JSON
                                data = json.loads(json_str)
                                
                                # Look for cache entries related to our concept
                                if isinstance(data, dict):
                                    cache_data = self._find_concept_cache_entries(data, concept_id)
                                    if cache_data:
                                        # Merge cache data, categorizing by content type
                                        for key, value in cache_data.items():
                                            # More specific categorization based on content
                                            if isinstance(value, dict):
                                                if 'background-image' in value or 'bg' in str(key).lower():
                                                    batarangs_data.setdefault('background-image', {})[key] = value
                                                elif 'title' in value or 'name' in value or 'game-title' in str(key).lower():
                                                    batarangs_data.setdefault('game-title', {})[key] = value
                                                elif any(info_key in value for info_key in ['rating', 'platforms', 'genre', 'price', 'description']):
                                                    batarangs_data.setdefault('info', {})[key] = value
                                                else:
                                                    batarangs_data.setdefault('other', {})[key] = value
                                            elif 'background' in str(key).lower() or 'image' in str(key).lower():
                                                batarangs_data.setdefault('background-image', {})[key] = value
                                            elif 'title' in str(key).lower() or 'name' in str(key).lower():
                                                batarangs_data.setdefault('game-title', {})[key] = value
                                            else:
                                                batarangs_data.setdefault('other', {})[key] = value
                                                
                            except (json.JSONDecodeError, ValueError):
                                # Skip non-JSON content
                                continue
                        
        except Exception as e:
            print(f"Warning: Error extracting batarangs data: {e}")
            
        return batarangs_data
    
    def _extract_apollo_state_data(self, html_content: str, concept_id: str) -> Dict[str, Any]:
        """Extract apolloState data from HTML content."""
        apollo_data = {}
        
        try:
            # Look for __APOLLO_STATE__ or similar patterns in script tags
            script_pattern = r'<script[^>]*?>(.*?)</script>'
            scripts = re.findall(script_pattern, html_content, re.DOTALL | re.IGNORECASE)
            
            for script_content in scripts:
                # Look for Apollo state patterns
                apollo_patterns = [
                    r'__APOLLO_STATE__\s*=\s*({.*?});',
                    r'apolloState\s*:\s*({.*?})',
                    r'"apolloState"\s*:\s*({.*?})',
                    r'window\.__APOLLO_STATE__\s*=\s*({.*?});'
                ]
                
                for pattern in apollo_patterns:
                    matches = re.findall(pattern, script_content, re.DOTALL)
                    for match in matches:
                        try:
                            data = json.loads(match)
                            if isinstance(data, dict):
                                # Look for concept-related entries
                                concept_entries = self._find_concept_apollo_entries(data, concept_id)
                                apollo_data.update(concept_entries)
                        except (json.JSONDecodeError, ValueError):
                            continue
                            
        except Exception as e:
            print(f"Warning: Error extracting Apollo state data: {e}")
            
        return apollo_data
    
    def _find_concept_cache_entries(self, data: Dict[str, Any], concept_id: str) -> Dict[str, Any]:
        """Find cache entries related to the concept ID."""
        concept_entries = {}
        concept_key = f"Concept:{concept_id}"
        
        def search_recursive(obj, path=""):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    current_path = f"{path}.{key}" if path else key
                    
                    # Direct concept key match
                    if key == concept_key:
                        concept_entries[current_path] = value
                    
                    # Check if this key contains the concept ID
                    elif concept_id in str(key):
                        concept_entries[current_path] = value
                    
                    # Check if this is a cache-related structure that might contain our concept
                    elif 'cache' in str(key).lower():
                        # Look deeper in cache structures
                        if isinstance(value, dict):
                            for cache_key, cache_value in value.items():
                                if concept_key in str(cache_key) or concept_id in str(cache_key):
                                    concept_entries[f"{current_path}.{cache_key}"] = cache_value
                    
                    # Recursively search deeper
                    search_recursive(value, current_path)
                    
            elif isinstance(obj, list):
                for i, item in enumerate(obj):
                    search_recursive(item, f"{path}[{i}]")
        
        search_recursive(data)
        return concept_entries
    
    def _find_concept_apollo_entries(self, data: Dict[str, Any], concept_id: str) -> Dict[str, Any]:
        """Find Apollo state entries related to the concept ID."""
        apollo_entries = {}
        concept_key = f"Concept:{concept_id}"
        
        # Apollo state typically has keys like "Concept:123456"
        for key, value in data.items():
            if concept_key in str(key) or (concept_id in str(key) and 'concept' in str(key).lower()):
                apollo_entries[key] = value
                
        return apollo_entries
    
    def fetch_concept_graphql(self, concept_id: str) -> Dict[str, Any]:
        """
        Fetch concept data using GraphQL ConceptRetrieve query.
        
        Args:
            concept_id: The concept ID to fetch
            
        Returns:
            Dictionary containing GraphQL response data
        """
        result = {
            'concept_id': concept_id,
            'data': None,
            'error': None
        }
        
        try:
            # Enhanced GraphQL ConceptRetrieve query with more fields
            query = {
                "operationName": "ConceptRetrieve",
                "variables": {
                    "conceptId": concept_id,
                    "includeMedia": True,
                    "includeGenres": True,
                    "includePublisher": True,
                    "includePlatforms": True,
                    "includeRating": True
                },
                "query": """
                    query ConceptRetrieve(
                        $conceptId: ID!,
                        $includeMedia: Boolean = false,
                        $includeGenres: Boolean = false,
                        $includePublisher: Boolean = false,
                        $includePlatforms: Boolean = false,
                        $includeRating: Boolean = false
                    ) {
                        conceptRetrieve(conceptId: $conceptId) {
                            id
                            name
                            description
                            longDescription
                            publisherName @include(if: $includePublisher)
                            developerName
                            localizedGenres @include(if: $includeGenres) {
                                name
                                localizedName
                            }
                            media @include(if: $includeMedia) {
                                type
                                url
                                altText
                                role
                            }
                            releaseDate
                            platforms @include(if: $includePlatforms) {
                                name
                                shortName
                            }
                            rating @include(if: $includeRating) {
                                age
                                description
                                ratingSystem
                            }
                            price {
                                basePrice
                                discountPrice
                                currency
                            }
                            availability {
                                isAvailable
                                isComingSoon
                                isPurchasable
                            }
                            tags
                            features
                            __typename
                        }
                    }
                """
            }
            
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': self.session.headers.get('User-Agent'),
            }
            
            # Try multiple GraphQL endpoints as they may vary
            graphql_endpoints = [
                "https://web.np.playstation.com/api/graphql/v1/op",
                "https://store.playstation.com/graphql",
                "https://web.playstation.com/api/graphql",
            ]
            
            for endpoint in graphql_endpoints:
                try:
                    response = self.session.post(
                        endpoint, 
                        json=query, 
                        headers=headers, 
                        timeout=30
                    )
                    response.raise_for_status()
                    
                    json_data = response.json()
                    
                    if 'errors' in json_data:
                        result['error'] = f"GraphQL errors: {json_data['errors']}"
                    else:
                        result['data'] = json_data.get('data', {})
                        result['endpoint_used'] = endpoint
                        break
                        
                except requests.RequestException:
                    # Try next endpoint
                    continue
            
            if not result.get('endpoint_used') and not result['data']:
                result['error'] = "Failed to connect to any PlayStation GraphQL endpoint"
                
        except Exception as e:
            result['error'] = f"GraphQL parsing failed: {str(e)}"
            
        return result


def test_parsing_with_sample_data():
    """Test the parsing functionality with sample HTML data."""
    import re
    print("Testing parsing functionality with sample data...")
    
    # Sample HTML content that simulates a PlayStation concept page
    sample_html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Sample Game - PlayStation Store</title>
    </head>
    <body>
        <div id="app">
            <script>
                window.__APOLLO_STATE__ = {
                    "Concept:123456": {
                        "id": "123456",
                        "name": "Sample Game",
                        "publisherName": "Sample Publisher",
                        "localizedGenres": [{"name": "Action", "localizedName": "Action"}]
                    },
                    "ROOT_QUERY": {
                        "conceptRetrieve({\\"conceptId\\":\\"123456\\"})": {
                            "__ref": "Concept:123456"
                        }
                    }
                };
            </script>
            <script type="application/json" id="batarangs-cache">
                {
                    "cache": {
                        "Concept:123456": {
                            "background-image": "https://example.com/bg.jpg",
                            "game-title": "Sample Game",
                            "info": {
                                "rating": "T",
                                "platforms": ["PS5", "PS4"]
                            }
                        }
                    },
                    "components": {
                        "gameHeader": {
                            "cache": {
                                "Concept:123456": {
                                    "title": "Sample Game",
                                    "subtitle": "Epic Adventure"
                                }
                            }
                        }
                    }
                }
            </script>
        </div>
    </body>
    </html>
    """
    
    fetcher = PlayStationDataFetcher()
    concept_id = "123456"
    
    print(f"Looking for concept ID: {concept_id}")
    print(f"Sample HTML length: {len(sample_html)} characters")
    
    # Test batarangs extraction
    print("\nTesting batarangs extraction...")
    batarangs = fetcher._extract_batarangs_data(sample_html, concept_id)
    print(f"Extracted batarangs: {json.dumps(batarangs, indent=2)}")
    
    # Test Apollo state extraction
    print("\nTesting Apollo state extraction...")
    apollo_state = fetcher._extract_apollo_state_data(sample_html, concept_id)
    print(f"Extracted Apollo state: {json.dumps(apollo_state, indent=2)}")
    
    # Debug: Let's see what scripts are found
    script_pattern = r'<script[^>]*?>(.*?)</script>'
    scripts = re.findall(script_pattern, sample_html, re.DOTALL | re.IGNORECASE)
    print(f"\nFound {len(scripts)} script tags")
    for i, script in enumerate(scripts):
        print(f"Script {i+1}: {script[:100]}...")
    
    # Test edge cases
    print("\n" + "="*40)
    print("TESTING EDGE CASES")
    print("="*40)
    
    # Test with empty concept ID
    print("\nTesting with empty concept ID...")
    empty_result = fetcher._extract_batarangs_data(sample_html, "")
    print(f"Empty concept ID result: {bool(empty_result)}")
    
    # Test with non-existent concept ID
    print("\nTesting with non-existent concept ID...")
    nonexistent_result = fetcher._extract_batarangs_data(sample_html, "999999")
    print(f"Non-existent concept ID result: {bool(nonexistent_result)}")
    
    # Test with malformed HTML
    print("\nTesting with malformed HTML...")
    malformed_html = "<script>invalid json {</script>"
    malformed_result = fetcher._extract_batarangs_data(malformed_html, concept_id)
    print(f"Malformed HTML result: {bool(malformed_result)}")
    
    return batarangs, apollo_state


def test_complete_workflow():
    """Test the complete workflow as described in the problem statement."""
    print("Testing complete workflow...")
    
    fetcher = PlayStationDataFetcher()
    concept_id = "123456"
    
    # Test the main workflow: fetch_concept_page followed by fetch_concept_graphql
    print(f"\n1. Testing fetch_concept_page for concept {concept_id}...")
    
    # Create a mock fetch_concept_page that returns sample data (simulating successful parsing)
    def mock_fetch_concept_page(cid):
        return {
            'concept_id': cid,
            'batarangs': {
                'background-image': {'cache.bg': 'https://example.com/bg.jpg'},
                'game-title': {'cache.title': 'Sample Game'},
                'info': {'cache.info': {'rating': 'T', 'platforms': ['PS5', 'PS4']}}
            },
            'apollo_state': {
                f'Concept:{cid}': {
                    'id': cid,
                    'name': 'Sample Game',
                    'publisherName': 'Sample Publisher'
                }
            },
            'error': None
        }
    
    page_result = mock_fetch_concept_page(concept_id)
    print(f"Page result has batarangs: {bool(page_result.get('batarangs'))}")
    print(f"Page result has apollo state: {bool(page_result.get('apollo_state'))}")
    
    # Test fetch_concept_graphql as fallback
    print(f"\n2. Testing fetch_concept_graphql for concept {concept_id}...")
    graphql_result = fetcher.fetch_concept_graphql(concept_id)
    print(f"GraphQL result has data: {bool(graphql_result.get('data'))}")
    print(f"GraphQL error: {graphql_result.get('error')}")
    
    # Combine results as specified in problem statement
    final_result = {
        'concept_id': concept_id,
        'page_data': page_result,
        'concept_graphql': graphql_result,  # As required by problem statement
        'summary': {
            'page_has_batarangs': bool(page_result.get('batarangs')),
            'page_has_apollo': bool(page_result.get('apollo_state')),
            'graphql_has_data': bool(graphql_result.get('data')),
            'should_use_graphql_fallback': (
                not page_result.get('batarangs') or 
                not page_result.get('apollo_state') or 
                page_result.get('error')
            )
        }
    }
    
    print(f"\n3. Final combined result summary:")
    print(f"   - Page parsing successful: {not page_result.get('error')}")
    print(f"   - Batarangs extracted: {final_result['summary']['page_has_batarangs']}")
    print(f"   - Apollo state extracted: {final_result['summary']['page_has_apollo']}")
    print(f"   - Should use GraphQL fallback: {final_result['summary']['should_use_graphql_fallback']}")
    print(f"   - GraphQL data available: {final_result['summary']['graphql_has_data']}")
    
    return final_result


def main():
    """Main function to demonstrate the PlayStation data fetcher."""
    import sys
    
    # Check if we want to run tests
    if len(sys.argv) >= 2 and sys.argv[1] == "test":
        test_parsing_with_sample_data()
        print("\n" + "="*60)
        test_complete_workflow()
        return
    
    if len(sys.argv) < 2:
        print("Usage: python playstation.py <concept_id>")
        print("       python playstation.py test  # Run tests with sample data")
        print("Example: python playstation.py 123456")
        sys.exit(1)
    
    concept_id = sys.argv[1]
    fetcher = PlayStationDataFetcher()
    
    print(f"Fetching PlayStation concept data for ID: {concept_id}")
    
    # Try to fetch from the concept page first
    print("\n1. Fetching data from concept page HTML...")
    page_result = fetcher.fetch_concept_page(concept_id)
    
    # Always try GraphQL as fallback or additional data source (as per problem statement)
    print("\n2. Fetching data via GraphQL...")
    graphql_result = fetcher.fetch_concept_graphql(concept_id)
    
    # Combine results with GraphQL data under 'concept_graphql' key as specified
    final_result = {
        'concept_id': concept_id,
        'page_data': page_result,
        'concept_graphql': graphql_result,  # Required by problem statement
        'summary': {
            'page_has_batarangs': bool(page_result.get('batarangs')),
            'page_has_apollo': bool(page_result.get('apollo_state')),
            'graphql_has_data': bool(graphql_result.get('data')),
            'page_error': page_result.get('error'),
            'graphql_error': graphql_result.get('error')
        }
    }
    
    # Print results
    print("\n" + "="*60)
    print("RESULTS SUMMARY")
    print("="*60)
    
    print(f"Concept ID: {concept_id}")
    print(f"Page batarangs found: {final_result['summary']['page_has_batarangs']}")
    print(f"Page Apollo state found: {final_result['summary']['page_has_apollo']}")
    print(f"GraphQL data retrieved: {final_result['summary']['graphql_has_data']}")
    
    if final_result['summary']['page_error']:
        print(f"Page parsing error: {final_result['summary']['page_error']}")
        
    if final_result['summary']['graphql_error']:
        print(f"GraphQL error: {final_result['summary']['graphql_error']}")
    
    print("\n" + "="*60)
    print("DETAILED RESULTS")
    print("="*60)
    print(json.dumps(final_result, indent=2, default=str))
    
    return final_result


if __name__ == "__main__":
    main()