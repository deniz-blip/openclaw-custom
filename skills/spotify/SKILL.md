---
name: spotify
description: Control playback, search music, and manage playlists on Spotify.
metadata: { "openclaw": { "emoji": "🎵", "requires": { "env": ["SPOTIFY_CLIENT_ID", "SPOTIFY_CLIENT_SECRET"] } } }
---

# Spotify Integration

You have access to the Spotify Web API using client credentials.

## Authentication
Client credentials are available as `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET`. You need to obtain an access token first.

### Get access token
```bash
curl -s -X POST 'https://accounts.spotify.com/api/token' \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$SPOTIFY_CLIENT_ID&client_secret=$SPOTIFY_CLIENT_SECRET"
```

This returns `{ "access_token": "...", "token_type": "Bearer", "expires_in": 3600 }`.
Use the access token for subsequent requests.

## API Base URL
`https://api.spotify.com/v1`

## Available Actions (with Client Credentials)

### Search for tracks, artists, albums
```bash
curl -s 'https://api.spotify.com/v1/search?q=QUERY&type=track,artist,album&limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### Get an artist
```bash
curl -s 'https://api.spotify.com/v1/artists/ARTIST_ID' \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### Get artist's top tracks
```bash
curl -s 'https://api.spotify.com/v1/artists/ARTIST_ID/top-tracks?market=US' \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### Get an album
```bash
curl -s 'https://api.spotify.com/v1/albums/ALBUM_ID' \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### Get track details
```bash
curl -s 'https://api.spotify.com/v1/tracks/TRACK_ID' \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

### Get playlist
```bash
curl -s 'https://api.spotify.com/v1/playlists/PLAYLIST_ID' \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

## Limitations
- Client credentials flow does NOT support playback control or user-specific data (playlists, saved tracks).
- For playback control, the user would need OAuth (user authorization flow) which requires a browser redirect.
- You CAN search, browse, and get public data about tracks, artists, albums, and public playlists.

## Rules
- Always obtain a fresh access token before making API calls.
- Present search results with track name, artist, album, and duration.
- If the user asks to play/pause, explain that playback control requires OAuth user authorization.
