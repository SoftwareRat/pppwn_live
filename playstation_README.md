# PlayStation Concept Data Retrieval

This script (`playstation.py`) fetches PlayStation concept page data by parsing HTML pages and using GraphQL queries as a fallback.

## Features

- **HTML Parsing**: Extracts 'batarangs' caches and apolloState data from PlayStation concept pages
- **Cache Data Extraction**: Collects entries under `cache` for `Concept:<id>` from embedded JSON components
- **Apollo State Parsing**: Extracts relevant entries from `apolloState` for the same `Concept:<id>`
- **GraphQL Fallback**: Provides `fetch_concept_graphql()` function for GraphQL `ConceptRetrieve` queries
- **Comprehensive Error Handling**: Gracefully handles network failures and parsing errors
- **Multiple URL Patterns**: Tries different PlayStation URL patterns to find concept data

## Usage

### Basic Usage

```bash
python playstation.py <concept_id>
```

Example:
```bash
python playstation.py 123456
```

### Run Tests

```bash
python playstation.py test
```

## Output

The script returns a comprehensive result structure:

```json
{
  "concept_id": "123456",
  "page_data": {
    "concept_id": "123456",
    "batarangs": {
      "background-image": {...},
      "game-title": {...},
      "info": {...},
      "other": {...}
    },
    "apollo_state": {
      "Concept:123456": {...}
    },
    "error": null
  },
  "concept_graphql": {
    "concept_id": "123456",
    "data": {...},
    "error": null
  },
  "summary": {
    "page_has_batarangs": true,
    "page_has_apollo": true,
    "graphql_has_data": false,
    "page_error": null,
    "graphql_error": "Failed to connect to any PlayStation GraphQL endpoint"
  }
}
```

## Dependencies

- Python 3.6+
- requests library

Install dependencies:
```bash
pip install -r requirements.txt
```

## Implementation Details

### Batarangs Cache Extraction

The script extracts batarangs cache data by:
1. Finding script tags containing JSON data
2. Parsing embedded JSON components
3. Searching for cache entries related to the concept ID
4. Categorizing data into: background-image, game-title, info, and other

### Apollo State Extraction

Extracts data from `__APOLLO_STATE__` objects by:
1. Locating Apollo state declarations in script tags
2. Parsing the JSON state data
3. Finding concept-related entries

### GraphQL Fallback

When HTML parsing fails or returns incomplete data, the script:
1. Issues a comprehensive GraphQL `ConceptRetrieve` query
2. Tries multiple PlayStation GraphQL endpoints
3. Returns structured concept metadata

## Error Handling

The script includes robust error handling for:
- Network connectivity issues
- Invalid HTML content
- Malformed JSON data
- Missing concept IDs
- GraphQL API failures

## Testing

The script includes comprehensive tests that validate:
- HTML parsing functionality
- Batarangs cache extraction
- Apollo state parsing
- Edge cases and error conditions
- Complete workflow integration