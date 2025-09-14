# RigRadar – Functional Requirements Document

## 1. Problem Description
Long–haul truck drivers lose valuable on-duty time trying to locate **truck stops, weigh stations**, and safe **overnight parking**.
Studies (e.g., U.S. DOT “Jason’s Law” surveys and ATRI research) show that drivers commonly spend about **45 – 75 minutes per day** searching for parking, detouring for fuel, or finding a scale.
This hidden delay wastes fuel, reduces driving hours, and complicates scheduling.
Without better tools, drivers—and the dispatchers or freight brokers who help plan their trips—cannot reliably pre-plan stops for rest, fueling, and weighing along the intended corridor.

## 2. Proposed Solution
RigRadar is a route-aware planning web app that:
- Builds a **pickup→drop-off corridor** with a configurable buffer (e.g. ±15 mi).
- Lists **Truck Stops**, **Rest Areas**, and auto-includes **Weigh Stations** inside that corridor.
- Lets users **filter** stops by provider and by **number of truck-parking spots**.
- Lets users **filter** stops by his prefered truck stops chains whether its **PILOT, LOVE'S, TA, PETRO , AMBEST or FLYING J** 
- Shows **nearest distance** from pickup and drop-off.
- Allows drivers to **select & save** preferred stops and view them on a **Leaflet map**.
- Provides **precise address and phone** for truck stops (and location info for rest areas & weigh stations).
- Allows the selected stop to be opened directly in **Google Maps** for turn-by-turn navigation.

## 3. Target Users
- **Drivers / Owner–Operators** – plan their own trips and stops.
- **Dispatchers / Driver Managers** – pre-plan routes for company drivers.
- **Freight Brokers** – verify route feasibility and available stops.

## 4. User Stories
- As a driver, I can **create a Load** with pickup and drop-off to generate a corridor route.
- As a driver, I can **set a buffer distance** to widen or narrow the corridor.
- As a driver, I can **filter truck stops** by brand/provider and by minimum parking spots.
- As a driver, I can **see the nearest truck stops/rest areas** and the **distance from pickup and drop-off**.
- As a driver, I can **click a stop on the map** to view its details, address and (where available) phone number.
- As a driver, I can **open the stop in Google Maps** for live navigation.
- As a dispatcher or broker, I can review and share the selected stops for each load.

## 5. Domain Model & Associations
- `Driver` has_many `Load`
- `Load` has_many `LoadStop`
- `LoadStop` belongs_to `Load` and polymorphic `stoppable`
  (`TruckStop`, `RestArea`, `WeighStation`)
- See ERD: `app/assets/images/erd.png`

## 6. UI Flow
1. **Landing page** – project overview & call-to-action.
2. **Sign in / Sign up** – Devise authentication.
3. **Loads#index** – list loads; create new load.
4. **Load#show (Pre-plan)** – configure corridor buffer & apply filters.
5. Select desired stops → **Save** → view pins on map and access Google Maps links.

## 7. Non-Functional Requirements
- **AuthN/AuthZ:** Devise + Pundit.
- **UI/UX:** Bootstrap 5 responsive design, Leaflet for interactive mapping.
- **Performance:** corridor filter query returns in <200 ms for typical routes.
- **Accessibility:** semantic HTML, alt text for images, WCAG contrast.
- **Security:** Rails credentials, SSL in production, strong parameters.

## 8. Success Criteria
- A driver can **Create → Pre-plan → Save → View pins** in under 60 seconds.
- Continuous Integration: Rubocop + RSpec tests pass on all pull requests to `main`.
