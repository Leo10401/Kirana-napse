"""The live calendar parser reads dates rather than assuming a fixed year."""

import unittest

from app.services.holiday_calendar import demand_multiplier, parse_ical_events


class HolidayCalendarTests(unittest.TestCase):
    def test_moving_festival_dates_are_taken_from_feed(self):
        events = []
        for index in range(30):
            day = index + 1
            name = "Diwali/Deepavali" if index == 0 else "Ordinary observance"
            events.append(
                f"BEGIN:VEVENT\r\nUID:event-{index}\r\n"
                f"DTSTART;VALUE=DATE:202710{day:02d}\r\n"
                f"SUMMARY:{name}\r\nEND:VEVENT\r\n"
            )
        payload = "BEGIN:VCALENDAR\r\n" + "".join(events) + "END:VCALENDAR"
        parsed = parse_ical_events(payload)
        self.assertEqual(len(parsed), 30)
        self.assertEqual(parsed[0]["date"], "2027-10-01")
        self.assertEqual(parsed[0]["expected_demand_multiplier"], 2.2)
        self.assertEqual(parsed[1]["expected_demand_multiplier"], 1.0)

    def test_feed_rejects_invalid_data(self):
        with self.assertRaises(ValueError):
            parse_ical_events("not a calendar")

    def test_event_name_matching(self):
        self.assertEqual(demand_multiplier("Dussehra"), 1.8)
        self.assertEqual(demand_multiplier("Diwali/Deepavali"), 2.2)
        self.assertEqual(demand_multiplier("Unlisted day"), 1.0)


if __name__ == "__main__":
    unittest.main()
