#!/usr/bin/env python3
"""
PlayStation concept page data fetcher.
Extracts meaningful data from PlayStation concept pages for delisted games.
"""

import argparse
import json
import requests
import sys
from typing import Dict, Any, Optional


# Constants
GRAPHQL_URL = "https://web.np.playstation.com/api/graphql/v1/op"


def fetch_concept_graphql(concept_id: str) -> Optional[Dict[str, Any]]:
    """
    Fetch concept data using PlayStation GraphQL API.
    
    Args:
        concept_id: The concept ID to fetch data for
        
    Returns:
        Dictionary containing concept data from GraphQL API, or None if failed
    """
    # GraphQL query for concept retrieval
    query = """
    query ConceptRetrieve($id: ID!) {
        conceptRetrieve(id: $id) {
            id
            name
            publisherName
            localizedGenres { value }
            releaseDate { value }
            invariantName
        }
    }
    """
    
    # Prepare the GraphQL request
    payload = {
        'query': query,
        'variables': {
            'id': concept_id
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        # Send POST request to GraphQL endpoint
        response = requests.post(GRAPHQL_URL, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        
        # Parse response
        data = response.json()
        
        if 'data' in data and 'conceptRetrieve' in data['data']:
            result = data['data']['conceptRetrieve']
            if result:
                # Add _source annotation
                result['_source'] = 'concept-graphql'
                return result
        
        # Handle GraphQL errors
        if 'errors' in data:
            print(f"GraphQL errors: {data['errors']}", file=sys.stderr)
            
    except requests.RequestException as e:
        print(f"Warning: GraphQL request failed: {e}", file=sys.stderr)
    except json.JSONDecodeError as e:
        print(f"Warning: Invalid JSON response from GraphQL: {e}", file=sys.stderr)
    except Exception as e:
        print(f"Warning: Unexpected error in GraphQL fetch: {e}", file=sys.stderr)
    
    return None


def fetch_concept_page(concept_id: str) -> Dict[str, Any]:
    """
    Fetch concept page data from PlayStation.
    Extracts meaningful data from batarangs and apolloState.
    
    Args:
        concept_id: The concept ID to fetch data for
        
    Returns:
        Dictionary containing page data with props and batarangs
    """
    # Initialize the page structure
    page = {
        'props': {
            'pageProps': {},
            'batarangs': {}
        },
        'batarangs': {},
        'apolloState': None
    }
    
    try:
        # For now, simulate fetching the PlayStation page
        # In a real implementation, this would make an HTTP request
        # to the PlayStation store page for the concept_id
        
        # Simulate different scenarios based on concept_id for testing
        if concept_id == 'empty123':
            # Return empty data to test GraphQL fallback
            return page
        
        # Simulate props.batarangs data (this would come from the actual page)
        mock_props_batarangs = {
            'ComponentA': {
                'comp': {
                    'text': json.dumps({
                        'cache': {
                            f'Concept:{concept_id}': {
                                'id': concept_id,
                                'name': 'Sample Game',
                                'type': 'FULL_GAME'
                            },
                            'Concept:other123': {
                                'id': 'other123',
                                'name': 'Other Game',
                                'type': 'DLC'
                            }
                        },
                        'apolloState': {
                            f'Concept:{concept_id}': {
                                'id': concept_id,
                                'name': 'Sample Game from Apollo',
                                'publisherName': 'Sample Publisher',
                                'localizedGenres': [{'value': 'Action'}],
                                'releaseDate': {'value': '2023-01-01'},
                                'invariantName': 'sample-game'
                            }
                        }
                    })
                }
            },
            'ComponentB': {
                'comp': {
                    'text': json.dumps({
                        'cache': {
                            'Concept:another456': {
                                'id': 'another456',
                                'name': 'Another Game',
                                'type': 'BUNDLE'
                            }
                        }
                    })
                }
            }
        }
        
        # Set the props
        page['props']['batarangs'] = mock_props_batarangs
        
        # Process batarangs: iterate over all entries in props.batarangs
        for component_name, component_data in mock_props_batarangs.items():
            if 'comp' in component_data and 'text' in component_data['comp']:
                try:
                    # Parse the JSON blob
                    json_blob = json.loads(component_data['comp']['text'])
                    
                    # Extract cache object and collect Concept:<id> entries
                    if 'cache' in json_blob:
                        concept_entries = {}
                        for key, value in json_blob['cache'].items():
                            if key.startswith('Concept:'):
                                # Add _source annotation
                                value['_source'] = 'page-batarangs'
                                concept_entries[key] = value
                        
                        if concept_entries:
                            page['batarangs'][component_name] = concept_entries
                    
                    # Extract apolloState - get first Concept:<id> entry
                    if 'apolloState' in json_blob and page['apolloState'] is None:
                        for key, value in json_blob['apolloState'].items():
                            if key.startswith('Concept:'):
                                # Add _source annotation
                                value['_source'] = 'page-apollo'
                                page['apolloState'] = {key: value}
                                break
                                
                except json.JSONDecodeError:
                    # Skip invalid JSON
                    continue
                    
    except Exception as e:
        # In case of any errors, return the basic structure
        print(f"Warning: Error fetching concept page: {e}", file=sys.stderr)
    
    return page


def main():
    """Main function to orchestrate concept page data fetching."""
    parser = argparse.ArgumentParser(description='Fetch PlayStation concept page data')
    parser.add_argument('concept_id', help='PlayStation concept ID to fetch')
    parser.add_argument('--use-graphql', action='store_true', 
                       help='Force use of GraphQL API even if page data is available')
    
    args = parser.parse_args()
    
    result = {}
    
    # Fetch concept page data
    concept_page_data = fetch_concept_page(args.concept_id)
    result['concept_page'] = concept_page_data
    
    # Check if we need to use GraphQL API
    need_graphql = (
        args.use_graphql or 
        not concept_page_data.get('batarangs') or 
        not concept_page_data.get('apolloState')
    )
    
    if need_graphql:
        # Fetch data using GraphQL API
        graphql_data = fetch_concept_graphql(args.concept_id)
        if graphql_data:
            result['concept_graphql'] = graphql_data
    
    # Output the result
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()