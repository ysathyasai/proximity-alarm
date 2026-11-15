package com.example.proximity_alarm

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ArrivalPolicyTest {
    @Test fun triggersInsideFallbackRadius() {
        assertTrue(ArrivalPolicy.shouldTrigger(1800.0, 15.0, 2000.0, null, 5))
    }

    @Test fun triggersWhenRouteEtaEntersPreparationWindow() {
        assertTrue(ArrivalPolicy.shouldTrigger(8000.0, 10.0, 2000.0, 240L, 5))
    }

    @Test fun fallbackStillWorksWithoutRoadEta() {
        assertTrue(ArrivalPolicy.shouldTrigger(1995.0, 10.0, 2000.0, null, 5))
    }

    @Test fun ignoresPoorFixForRadiusAllowance() {
        assertFalse(ArrivalPolicy.shouldTrigger(2100.0, 150.0, 2000.0, null, 5))
    }

    @Test fun doesNotTriggerWhenNeitherConditionIsMet() {
        assertFalse(ArrivalPolicy.shouldTrigger(10_000.0, 12.0, 2000.0, 900L, 5))
    }

    @Test fun rejectsInvalidDistance() {
        assertFalse(ArrivalPolicy.shouldTrigger(Double.NaN, 5.0, 2000.0, 10L, 5))
    }
}
