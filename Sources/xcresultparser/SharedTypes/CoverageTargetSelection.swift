//
//  CoverageTargetSelection.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 22.02.26.
//

import Foundation

struct CoverageTargetSelection {
    let selectedTargets: Set<String>
    let unmatchedRequested: Set<String>
    let availableTargets: Set<String>
}

extension CoverageTargetSelection {
    init(with filters: [String], from availableTargets: [String]) {
        let availableTargetSet = Set(availableTargets)
        let availableNormalizedTargets = Set(availableTargets.map { target in
            String(target.split(separator: ".").first ?? Substring(target))
        })

        guard !filters.isEmpty else {
            self.init(
                selectedTargets: Set(availableTargets),
                unmatchedRequested: [],
                availableTargets: availableTargetSet
            )
            return
        }

        let filterSet = Set(filters)
        let filtered = availableTargets.filter { thisTarget in
            let stripped = String(thisTarget.split(separator: ".").first ?? Substring(thisTarget))
            return filterSet.contains(stripped) || filterSet.contains(thisTarget)
        }
        let unmatched = filterSet.filter { requested in
            !availableTargetSet.contains(requested) && !availableNormalizedTargets.contains(requested)
        }

        self.init(
            selectedTargets: Set(filtered),
            unmatchedRequested: Set(unmatched),
            availableTargets: availableTargetSet
        )
    }
}
