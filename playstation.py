#!/usr/bin/env python3
"""
PlayStation Concept Data Retrieval Script

This script fetches PlayStation concept page data by:
1. Parsing HTML pages to extract 'batarangs' caches and apolloState data
2. Using GraphQL queries as a fallback to retrieve concept metadata
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
            # Construct concept page URL - this is a placeholder pattern
            # Real PlayStation URLs may have different patterns
            url = f"{self.base_url}/en-us/concept/{concept_id}"
            
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            html_content = response.text
            
            # Extract batarangs caches from embedded JSON
            result['batarangs'] = self._extract_batarangs_data(html_content, concept_id)
            
            # Extract apolloState data
            result['apollo_state'] = self._extract_apollo_state_data(html_content, concept_id)
            
        except requests.RequestException as e:
            result['error'] = f"HTTP request failed: {str(e)}"
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
                    
                    # Check if this is a concept-related cache entry
                    if concept_key in str(key) or concept_id in str(key):
                        concept_entries[current_path] = value
                    
                    # Check if the key contains 'cache' and dig deeper
                    if 'cache' in str(key).lower():
                        search_recursive(value, current_path)
                    else:
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
            # GraphQL ConceptRetrieve query
            query = {
                "operationName": "ConceptRetrieve",
                "variables": {
                    "conceptId": concept_id,
                    "includeMedia": True,
                    "includeGenres": True,
                    "includePublisher": True
                },
                "query": """
                    query ConceptRetrieve($conceptId: ID!, $includeMedia: Boolean = false, $includeGenres: Boolean = false, $includePublisher: Boolean = false) {
                        conceptRetrieve(conceptId: $conceptId) {
                            id
                            name
                            description
                            publisherName @include(if: $includePublisher)
                            localizedGenres @include(if: $includeGenres) {
                                name
                                localizedName
                            }
                            media @include(if: $includeMedia) {
                                type
                                url
                                altText
                            }
                            releaseDate
                            platforms {
                                name
                            }
                            rating {
                                age
                                description
                            }
                        }
                    }
                """
            }
            
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            }
            
            response = self.session.post(
                self.graphql_url, 
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
                
        except requests.RequestException as e:
            result['error'] = f"GraphQL request failed: {str(e)}"
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
    
    return batarangs, apollo_state


def main():
    """Main function to demonstrate the PlayStation data fetcher."""
    import sys
    
    # Check if we want to run tests
    if len(sys.argv) >= 2 and sys.argv[1] == "test":
        test_parsing_with_sample_data()
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
    
    # Always try GraphQL as fallback or additional data source
    print("\n2. Fetching data via GraphQL...")
    graphql_result = fetcher.fetch_concept_graphql(concept_id)
    
    # Combine results
    final_result = {
        'concept_id': concept_id,
        'page_data': page_result,
        'concept_graphql': graphql_result,
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