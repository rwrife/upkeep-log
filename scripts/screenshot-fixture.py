#!/usr/bin/env python3
"""Write fictional screenshot data into a fresh, dedicated simulator container."""
import datetime as dt
import json
import pathlib
import sys
import uuid


def identifier(label):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, 'upkeep-log-screenshots/' + label)).upper()


def day(offset):
    return (dt.date.today() + dt.timedelta(days=offset)).isoformat()


home = identifier('home')
rooms = [dict(id=identifier(name), homeID=home, name=name)
         for name in ['Kitchen', 'Utility room', 'Living room']]
assets = [dict(id=identifier(name), homeID=home, roomID=identifier(room), name=name)
          for name, room in [('Refrigerator', 'Kitchen'), ('HVAC system', 'Utility room')]]


def task(name, offset, recurrence='months', interval=1):
    return dict(id=identifier(name), homeID=home, name=name, startDay=day(offset),
                recurrence=recurrence, interval=interval, isPaused=False)


tasks = [task('Replace HVAC filter', -3, interval=3),
         task('Test smoke alarms', 0),
         task('Clean kitchen sink disposal', 0),
         task('Check under sinks for leaks', 3),
         task('Vacuum refrigerator coils', 7, interval=6),
         task('Inspect weather stripping', 14, 'years'),
         task('Clean dryer vent', -7, 'years'),
         task('Flush water heater', -14, 'years')]
completions = []
for name, offset, notes, parts, cost in [
    ('Clean dryer vent', -7, 'Cleared lint from the duct and outside vent. Airflow is good.', 'Vent brush kit', 2499),
    ('Flush water heater', -14, 'Flushed sediment and checked the pressure relief valve.', '', 0),
]:
    completions.append(dict(id=identifier(name + '/completion'), taskID=identifier(name),
        scheduledDay=day(offset), revisions=[dict(id=identifier(name + '/revision'),
        revisedAt=day(offset) + 'T12:00:00Z', actualDay=day(offset), notes=notes,
        parts=parts, costMinorUnits=cost, currency='USD')]))
state = dict(homes=[dict(id=home, name='Maple House', address='Our family home')],
             rooms=rooms, assets=assets, tasks=tasks, completions=completions, snoozes={})
path = pathlib.Path(sys.argv[1]) / 'Library' / 'Application Support' / 'upkeep-log.json'
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(state, indent=2) + '\n')
