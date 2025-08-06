#!/usr/bin/env python3
"""
PlayStation Game Metadata Scraper

Retrieves PlayStation game metadata from multiple sources with fallback strategies
for maximum coverage, especially for delisted games.
"""

import json
import re
import requests
from typing import Dict, Any, Optional
from urllib.parse import urljoin
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class PlayStationMetadataFetcher:
    """Fetches PlayStation game metadata from multiple sources."""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        
        # GraphQL endpoint for PlayStation Store
        self.graphql_url = "https://web.np.playstation.com/api/graphql/v1/op"
        
    def fetch_container_api(self, content_id: str) -> Optional[Dict[str, Any]]:
        """Fetch metadata using container API calls."""
        try:
            # Placeholder for container API implementation
            # This would typically call PlayStation's container API
            logger.info(f"Attempting container API for {content_id}")
            return None  # Simulating failure for delisted games
        except Exception as e:
            logger.error(f"Container API failed for {content_id}: {e}")
            return None
    
    def scrape_html(self, content_id: str) -> Dict[str, Any]:
        """
        Scrape HTML page for metadata including JSON-LD and __NEXT_DATA__.
        
        Args:
            content_id: PlayStation content ID
            
        Returns:
            Dictionary containing scraped data with _source annotations
        """
        result = {}
        
        try:
            # Construct PlayStation Store URL
            url = f"https://store.playstation.com/en-us/product/{content_id}"
            logger.info(f"Scraping HTML from {url}")
            
            response = self.session.get(url)
            response.raise_for_status()
            html_content = response.text
            
            # Extract JSON-LD data
            json_ld_data = self._extract_json_ld(html_content)
            if json_ld_data:
                result['json_ld'] = {
                    '_source': 'json_ld_scrape',
                    'data': json_ld_data
                }
            
            # Extract __NEXT_DATA__ JSON blob
            next_data = self._extract_next_data(html_content)
            if next_data:
                result['next_data'] = {
                    '_source': 'next_data_scrape', 
                    'data': next_data
                }
            
        except Exception as e:
            logger.error(f"HTML scraping failed for {content_id}: {e}")
        
        return result
    
    def _extract_json_ld(self, html_content: str) -> Optional[Dict[str, Any]]:
        """Extract JSON-LD structured data from HTML."""
        try:
            # Look for JSON-LD script tags
            json_ld_pattern = r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>'
            matches = re.findall(json_ld_pattern, html_content, re.DOTALL | re.IGNORECASE)
            
            for match in matches:
                try:
                    json_data = json.loads(match.strip())
                    if json_data:  # Return first valid JSON-LD found
                        return json_data
                except json.JSONDecodeError:
                    continue
                    
        except Exception as e:
            logger.error(f"JSON-LD extraction failed: {e}")
        
        return None
    
    def _extract_next_data(self, html_content: str) -> Optional[Dict[str, Any]]:
        """
        Extract product data from __NEXT_DATA__ JSON blob.
        
        Looks for data under props.pageProps.productRetrieve or props.pageProps.product
        """
        try:
            # Look for __NEXT_DATA__ script tag
            next_data_pattern = r'<script[^>]*id=["\']__NEXT_DATA__["\'][^>]*>(.*?)</script>'
            match = re.search(next_data_pattern, html_content, re.DOTALL | re.IGNORECASE)
            
            if not match:
                return None
                
            try:
                next_data = json.loads(match.group(1).strip())
                
                # Navigate to product data
                props = next_data.get('props', {})
                page_props = props.get('pageProps', {})
                
                # Check for productRetrieve first, then product
                product_data = (page_props.get('productRetrieve') or 
                              page_props.get('product') or
                              page_props.get('productData'))
                
                if product_data:
                    return product_data
                    
                # If no direct product data, return entire pageProps for analysis
                if page_props:
                    return page_props
                    
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse __NEXT_DATA__ JSON: {e}")
                
        except Exception as e:
            logger.error(f"__NEXT_DATA__ extraction failed: {e}")
        
        return None
    
    def fetch_tmdb_fallback(self, content_id: str) -> Optional[Dict[str, Any]]:
        """Fetch metadata from TMDB as fallback."""
        try:
            # Placeholder for TMDB API implementation
            logger.info(f"Attempting TMDB fallback for {content_id}")
            return None  # Simulating no TMDB data available
        except Exception as e:
            logger.error(f"TMDB fallback failed for {content_id}: {e}")
            return None
    
    def fetch_graphql_persisted(self, content_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch metadata using persisted GraphQL queries.
        
        Args:
            content_id: PlayStation content ID
            
        Returns:
            GraphQL response data or None if failed
        """
        try:
            # Persisted query hash for ProductRetrieve operation
            persisted_query_hash = "..."  # This would be the actual hash
            
            params = {
                'operationName': 'ProductRetrieve',
                'extensions': json.dumps({
                    'persistedQuery': {
                        'version': 1,
                        'sha256Hash': persisted_query_hash
                    }
                }),
                'variables': json.dumps({
                    'productId': content_id,
                    'countryCode': 'US',
                    'languageCode': 'en'
                })
            }
            
            logger.info(f"Attempting persisted GraphQL query for {content_id}")
            response = self.session.get(self.graphql_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            if data.get('data') and not data.get('errors'):
                return data['data']
                
        except Exception as e:
            logger.error(f"Persisted GraphQL query failed for {content_id}: {e}")
        
        return None
    
    def fetch_graphql_direct(self, content_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch metadata using direct GraphQL query POST.
        
        Sends the full GraphQL query text as a POST request when persisted queries fail.
        
        Args:
            content_id: PlayStation content ID
            
        Returns:
            GraphQL response data or None if failed
        """
        try:
            # Full GraphQL query text (copied from achievements-app/psn-api)
            query = """
            query ProductRetrieve($productId: String!, $countryCode: String!, $languageCode: String!) {
                productRetrieve(productId: $productId, countryCode: $countryCode, languageCode: $languageCode) {
                    id
                    name
                    description
                    longDescription
                    releaseDate
                    images {
                        role
                        url
                    }
                    media {
                        role
                        type
                        url
                    }
                    genres {
                        name
                    }
                    platforms {
                        name
                        platformFamily
                    }
                    price {
                        basePrice
                        discount
                        isPlus
                    }
                    ratings {
                        rating
                        system
                    }
                    publisher
                    developer
                    skus {
                        id
                        name
                        price {
                            basePrice
                            discount
                        }
                    }
                }
            }
            """
            
            payload = {
                'query': query,
                'variables': {
                    'productId': content_id,
                    'countryCode': 'US', 
                    'languageCode': 'en'
                }
            }
            
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            }
            
            logger.info(f"Attempting direct GraphQL query for {content_id}")
            response = self.session.post(self.graphql_url, 
                                       json=payload, 
                                       headers=headers)
            response.raise_for_status()
            
            data = response.json()
            if data.get('data') and not data.get('errors'):
                return data['data']
            elif data.get('errors'):
                logger.warning(f"GraphQL errors for {content_id}: {data['errors']}")
                
        except Exception as e:
            logger.error(f"Direct GraphQL query failed for {content_id}: {e}")
        
        return None


def main(content_id: str) -> Dict[str, Any]:
    """
    Main function to fetch PlayStation game metadata using multiple fallback strategies.
    
    Args:
        content_id: PlayStation content ID to fetch metadata for
        
    Returns:
        Dictionary containing all available metadata with source annotations
    """
    fetcher = PlayStationMetadataFetcher()
    result = {}
    
    logger.info(f"Starting metadata fetch for content ID: {content_id}")
    
    # Try container API first
    container_data = fetcher.fetch_container_api(content_id)
    if container_data:
        result['container_api'] = {
            '_source': 'container_api',
            'data': container_data
        }
    
    # Scrape HTML for JSON-LD and __NEXT_DATA__
    html_data = fetcher.scrape_html(content_id)
    if html_data:
        result.update(html_data)
    
    # Try persisted GraphQL query
    graphql_data = fetcher.fetch_graphql_persisted(content_id)
    if graphql_data:
        result['graphql_persisted'] = {
            '_source': 'graphql_persisted',
            'data': graphql_data
        }
    else:
        # If persisted GraphQL returns None, try direct GraphQL query
        direct_graphql_data = fetcher.fetch_graphql_direct(content_id)
        if direct_graphql_data:
            result['graphql_direct'] = {
                '_source': 'graphql_direct',
                'data': direct_graphql_data
            }
    
    # Try TMDB fallback if needed
    tmdb_data = fetcher.fetch_tmdb_fallback(content_id)
    if tmdb_data:
        result['tmdb_fallback'] = {
            '_source': 'tmdb_fallback',
            'data': tmdb_data
        }
    
    # Log summary of data sources found
    sources_found = [key for key in result.keys()]
    logger.info(f"Metadata fetch completed for {content_id}. Sources found: {sources_found}")
    
    return result


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python playstation.py <content_id>")
        sys.exit(1)
    
    content_id = sys.argv[1]
    metadata = main(content_id)
    
    # Pretty print the results
    print(json.dumps(metadata, indent=2, ensure_ascii=False))