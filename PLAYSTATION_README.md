# PlayStation Metadata Scraper

A comprehensive PlayStation game metadata fetcher with multiple fallback strategies for maximum coverage, especially for delisted games.

## Features

### Core Functionality
- **Container API calls**: Primary metadata source from PlayStation's container API
- **HTML scraping**: Extract JSON-LD structured data and embedded JavaScript data
- **GraphQL queries**: Both persisted and direct GraphQL query support
- **TMDB fallback**: Additional metadata from The Movie Database

### New Fallback Strategies

#### 1. __NEXT_DATA__ JSON Extraction
Extracts product data embedded in the page's `__NEXT_DATA__` JavaScript blob. This data is often available even for delisted games.

- Looks for data under `props.pageProps.productRetrieve` or `props.pageProps.product`
- Provides comprehensive game information including pricing, ratings, and release dates
- Source annotation: `_source: "next_data_scrape"`

#### 2. Direct GraphQL Queries
When persisted GraphQL queries fail, sends the full GraphQL query text as a POST request to fetch product metadata directly.

- Uses explicit GraphQL query text (copied from achievements-app/psn-api)
- Includes appropriate headers and request formatting
- Fallback for when persisted query endpoints return no data
- Source annotation: `_source: "graphql_direct"`

## Usage

### Command Line
```bash
python playstation.py <content_id>
```

### As a Module
```python
from playstation import main

# Fetch metadata for a PlayStation game
metadata = main("UP9000-CUSA15609_00-MARVELSSPIDERMAN")
print(metadata)
```

## Output Format

All data sources are included in the final JSON output with proper `_source` annotations:

```json
{
  "container_api": {
    "_source": "container_api",
    "data": { ... }
  },
  "json_ld": {
    "_source": "json_ld_scrape", 
    "data": { ... }
  },
  "next_data": {
    "_source": "next_data_scrape",
    "data": { ... }
  },
  "graphql_persisted": {
    "_source": "graphql_persisted",
    "data": { ... }
  },
  "graphql_direct": {
    "_source": "graphql_direct",
    "data": { ... }
  },
  "tmdb_fallback": {
    "_source": "tmdb_fallback",
    "data": { ... }
  }
}
```

## Testing

Run the test suite:
```bash
python test_playstation.py
```

See the fallback strategies in action:
```bash
python demo_fallbacks.py
```

## Dependencies

- `requests`: For HTTP requests
- `json`: For JSON parsing (built-in)
- `re`: For regex pattern matching (built-in)

## Error Handling

The script gracefully handles failures from individual data sources and continues attempting other fallback strategies. All errors are logged for debugging purposes while maintaining script execution.