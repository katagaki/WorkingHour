//
//  WorkplaceEditorView.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/20.
//

import MapKit
import SwiftData
import SwiftUI

struct WorkplaceEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var workplace: Workplace?

    @State private var name: String = ""
    @State private var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: 35.6812, longitude: 139.7671  // Tokyo Station default
    )
    @State private var radius: Double = 100.0
    @State private var cameraPosition: MapCameraPosition = .automatic

    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false

    private var isEditing: Bool {
        workplace != nil
    }

    var body: some View {
        List {
            Section {
                TextField("Workplace.Name.Placeholder", text: $name)
            } header: {
                Text("Workplace.Name")
            }

            Section {
                TextField("Workplace.Search.Placeholder", text: $searchText)
                    .textContentType(.fullStreetAddress)
                    .onSubmit {
                        searchLocation()
                    }

                if !searchResults.isEmpty {
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            selectSearchResult(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 2.0) {
                                Text(item.name ?? "")
                                    .foregroundStyle(.primary)
                                if let subtitle = item.placemark.formattedAddress {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Workplace.Location")
            }

            Section {
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    MapCircle(
                        center: coordinate,
                        radius: radius
                    )
                    .foregroundStyle(.accent.opacity(0.2))
                    .stroke(.accent, lineWidth: 2.0)

                    Annotation("", coordinate: coordinate) {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(.accent)
                            .font(.title2)
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .onTapGesture { _ in
                    // Map tap handling is done via long press
                }

                VStack(alignment: .leading, spacing: 8.0) {
                    HStack {
                        Text("Workplace.Radius")
                        Spacer()
                        Text(String(format: "%.0f", radius) + " "
                             + String(localized: "Workplace.Radius.Meters"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $radius, in: 50...500, step: 25)
                        .tint(.accent)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Workplace.Map")
            } footer: {
                Text("Workplace.Map.Footer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(isEditing ? "Workplace.Edit" : "Workplace.Add")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Shared.Save") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task {
            if let workplace {
                name = workplace.name
                coordinate = CLLocationCoordinate2D(
                    latitude: workplace.latitude,
                    longitude: workplace.longitude
                )
                radius = workplace.radius
            }
            updateCameraPosition()
        }
        .onChange(of: radius) { _, _ in
            updateCameraPosition()
        }
    }

    private func updateCameraPosition() {
        let regionRadius = max(radius * 3, 500)
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        ))
    }

    private func searchLocation() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            isSearching = false
            if let response {
                searchResults = Array(response.mapItems.prefix(5))
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        coordinate = item.placemark.coordinate
        if name.isEmpty {
            name = item.name ?? ""
        }
        searchResults = []
        searchText = ""
        updateCameraPosition()
    }

    private func save() {
        if let workplace {
            workplace.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            workplace.latitude = coordinate.latitude
            workplace.longitude = coordinate.longitude
            workplace.radius = radius
        } else {
            let newWorkplace = Workplace(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: radius
            )
            modelContext.insert(newWorkplace)
        }

        do {
            try modelContext.save()
            DataManager.shared.loadAll()
        } catch {
            log("WorkplaceEditorView: Error saving workplace: \(error)")
        }

        // Refresh geofencing
        GeofencingManager.shared.startMonitoringWorkplaces()

        dismiss()
    }
}

// MARK: - CLPlacemark Extension

extension CLPlacemark {
    var formattedAddress: String? {
        let components = [
            subThoroughfare,
            thoroughfare,
            locality,
            administrativeArea,
            postalCode,
            country
        ].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
