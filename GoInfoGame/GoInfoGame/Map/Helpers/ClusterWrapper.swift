//
//  ClusterWrapper.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import ClusterMap
import MapKit
import Foundation

final class ClusterWrapper {
    private var clusterManager: ClusterManager<DisplayUnitAnnotation>?

    func updateClusters(mapView: MKMapView, items: [DisplayUnitAnnotation]) {
        guard mapView.window != nil else { return }

        let safeItems = items.filter {
            CLLocationCoordinate2DIsValid($0.coordinate) &&
            $0.coordinate.latitude.isFinite &&
            $0.coordinate.longitude.isFinite
        }

        let mapSize = mapView.bounds.size
        let region = mapView.region

        guard mapSize.width > 0, mapSize.height > 0,
              region.center.latitude.isFinite, region.center.longitude.isFinite else {
            print("❌ Invalid map region or size — skipping clustering")
            return
        }


        // 🚨 Important: Cancel previous clusters and recreate for fresh reload
        Task.detached(priority: .background) {
            let clusterManager = ClusterManager<DisplayUnitAnnotation>(
                configuration: .init(
                    cellSizeForZoomLevel: { _ in CGSize(width: 64, height: 64) }
                )
            )

            await clusterManager.add(safeItems)
            
            guard mapSize.width > 0, mapSize.height > 0,
                  region.center.latitude.isFinite, region.center.longitude.isFinite else {
                print("❌ Skipping reload due to invalid map size or region")
                return
            }

            do {
                let diff = await clusterManager.reload(
                    mapViewSize: mapSize,
                    coordinateRegion: region
                )

                await MainActor.run {
                    // Clean old annotations
                    mapView.removeAnnotations(mapView.annotations)

                    for insertion in diff.insertions {
                        switch insertion {
                        case .annotation(let ann):
                            mapView.addAnnotation(ann)

                        case .cluster(let cluster):
                            if cluster.coordinate.latitude.isFinite,
                               cluster.coordinate.longitude.isFinite {
                                let clusterAnn = DisplayClusterAnnotation(
                                    coordinate: cluster.coordinate,
                                    count: cluster.memberAnnotations.count
                                )
                                mapView.addAnnotation(clusterAnn)
                            } else {
                                print("⚠️ Skipped invalid cluster coordinate")
                            }
                        }
                    }

                }
            } catch {
                print("❌ ClusterMap reload failed: \(error)")
            }

            // Keep reference alive
            self.clusterManager = clusterManager
        }
    }
}
