# 0003 — A recording's origin is an area, not a point

**Status:** accepted

## Context
Each recording shows where it comes from. A first draft stored a point with a ~1 km fuzzing radius.
In practice people describe origins as places: "Tabriz", one of its suburbs, "the villages around
Maragheh".

## Options
- **Point + radius:** easy to store, but invents precision nobody has and still hints at a home.
- **Area:** an OpenStreetMap boundary chosen by search, or a polygon drawn by the uploader when OSM
  has no fitting boundary.

## Decision
Areas. Places are stored once (PostGIS multipolygon + a label point for the pin) and reused by
OSM id, so "Tabriz" exists once. The map shows clustered pins when zoomed out and shaded outlines
when zoomed in.

## Consequences
- Privacy comes from the data model itself: no exact location is ever stored.
- Boundary lookups go through the Worker (uploaders only, cached 7 days), so visitors' browsers
  never contact the geocoders and the services' usage policies are respected.
