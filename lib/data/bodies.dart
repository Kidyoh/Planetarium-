import 'package:flutter/material.dart';

/// Surface model indices understood by `planet.frag`.
abstract final class BodyType {
  static const mercury = 0.0;
  static const venus = 1.0;
  static const earth = 2.0;
  static const mars = 3.0;
  static const jupiter = 4.0;
  static const saturn = 5.0;
  static const uranus = 6.0;
  static const neptune = 7.0;
  static const rocky = 8.0;
  static const icy = 9.0;
  static const hazy = 10.0;
  static const star = 11.0;
}

class Stat {
  const Stat(this.label, this.value, this.unit);
  final String label;
  final String value;
  final String unit;
}

class Milestone {
  const Milestone(this.year, this.title, this.text);
  final String year;
  final String title;
  final String text;
}

class Layer {
  const Layer(this.name, this.radius, this.color);
  final String name;

  /// Outer edge of the layer as a fraction of the body's radius.
  final double radius;
  final Color color;
}

class Body {
  const Body({
    required this.id,
    required this.name,
    required this.kind,
    required this.type,
    required this.colA,
    required this.colB,
    required this.atmo,
    required this.accent,
    required this.short,
    required this.discover,
    required this.sectionTitle,
    required this.section,
    required this.stats,
    required this.history,
    required this.layers,
    required this.diameterKm,
    this.atmoStr = 0.0,
    this.ringIn = 0.0,
    this.ringOut = 0.0,
    this.ringTilt = 0.0,
    this.tilt = 0.0,
    this.spin = 0.12,
    this.seed = 0.0,
    this.orbitAu = 0.0,
    this.companion,
    this.parentName,
  });

  final String id;
  final String name;
  final String kind;
  final double type;
  final Color colA;
  final Color colB;
  final Color atmo;
  final double atmoStr;
  final Color accent;
  final double ringIn;
  final double ringOut;
  final double ringTilt;
  final double tilt;

  /// Visual spin speed in radians per second.
  final double spin;
  final double seed;
  final double orbitAu;
  final double diameterKm;

  final String short;
  final String discover;
  final String sectionTitle;
  final String section;
  final List<Stat> stats;
  final List<Milestone> history;
  final List<Layer> layers;

  /// The body shown when scrolling past this one in space view: a moon,
  /// or the Sun for the moonless inner planets.
  final Body? companion;

  /// For moons: the planet they orbit.
  final String? parentName;

  bool get isStar => type == BodyType.star;
  bool get hasRing => ringOut > 0;
}

const sun = Body(
  id: 'sun',
  name: 'Sun',
  kind: 'G-type star',
  type: BodyType.star,
  colA: Color(0xFFFFE6A6),
  colB: Color(0xFFF26A1B),
  atmo: Color(0xFFFF9A3C),
  atmoStr: 1.0,
  accent: Color(0xFFFFB547),
  spin: 0.05,
  diameterKm: 1392700,
  short:
      'The star at the heart of our solar system. Its gravity holds everything '
      'in orbit, from the planets to the farthest comets.',
  discover:
      'The Sun is a 4.6-billion-year-old ball of hot plasma, mostly hydrogen '
      'and helium. In its core, about 600 million tonnes of hydrogen fuse into '
      'helium every second, releasing the energy that lights and warms the '
      'whole solar system.',
  sectionTitle: 'Solar wind',
  section:
      'The Sun constantly blows a stream of charged particles into space. This '
      'solar wind carves out a bubble around the planets called the '
      'heliosphere, and when it strikes Earth\'s magnetic field it paints the '
      'sky with auroras.',
  stats: [
    Stat('Diameter', '1.39M', 'km'),
    Stat('Surface', '5,500', '°C'),
    Stat('Core', '15M', '°C'),
    Stat('Gravity', '274', 'm/s²'),
    Stat('Rotation', '25–35', 'days'),
    Stat('Light to Earth', '8.3', 'min'),
  ],
  history: [
    Milestone('1610', 'Sunspots', 'Early telescope observers record dark spots drifting across the solar disc.'),
    Milestone('1868', 'Helium found', 'A new element is identified in the solar spectrum, decades before it is found on Earth.'),
    Milestone('1995', 'SOHO', 'The Solar and Heliospheric Observatory begins watching the Sun without interruption.'),
    Milestone('2024', 'Closest touch', 'Parker Solar Probe skims just 6.1 million km above the Sun\'s surface.'),
  ],
  layers: [
    Layer('Convective zone', 1.0, Color(0xFFFFB547)),
    Layer('Radiative zone', 0.7, Color(0xFFF58A2E)),
    Layer('Core', 0.25, Color(0xFFFFF1C2)),
  ],
);

const moon = Body(
  id: 'moon',
  name: 'Moon',
  kind: 'Natural satellite',
  parentName: 'Earth',
  type: BodyType.rocky,
  colA: Color(0xFFB9B5AE),
  colB: Color(0xFF5E5B57),
  atmo: Color(0xFFFFFFFF),
  accent: Color(0xFFBDBDBD),
  spin: 0.05,
  seed: 3.0,
  diameterKm: 3474,
  short:
      'Is an astronomical body that orbits planet Earth, being Earth\'s only '
      'permanent natural satellite.',
  discover:
      'The Moon is an astronomical body that orbits planet Earth, being '
      'Earth\'s only permanent natural satellite. It is the fifth-largest '
      'natural satellite in the Solar System, and the largest among planetary '
      'satellites relative to the size of the planet that it orbits.',
  sectionTitle: 'Formation',
  section:
      'The Moon is thought to have formed about 4.51 billion years ago, not '
      'long after Earth. The most widely accepted explanation is that the Moon '
      'formed from the debris left over after a giant impact between Earth and '
      'a Mars-sized body called Theia.',
  stats: [
    Stat('Diameter', '3,474', 'km'),
    Stat('From Earth', '384,400', 'km'),
    Stat('Orbit', '27.3', 'days'),
    Stat('Gravity', '1.62', 'm/s²'),
    Stat('Day temp', '127', '°C'),
    Stat('Night temp', '-173', '°C'),
  ],
  history: [
    Milestone('1959', 'Luna 2', 'The first human-made object reaches the lunar surface.'),
    Milestone('1966', 'Luna 9', 'First soft landing and first photos from the surface.'),
    Milestone('1969', 'Apollo 11', 'Neil Armstrong and Buzz Aldrin walk on the Sea of Tranquility.'),
    Milestone('2019', 'Chang\'e 4', 'First soft landing on the far side of the Moon.'),
  ],
  layers: [
    Layer('Crust', 1.0, Color(0xFFBDB8B0)),
    Layer('Mantle', 0.97, Color(0xFF8D6E63)),
    Layer('Core', 0.2, Color(0xFFFFB74D)),
  ],
);

const phobos = Body(
  id: 'phobos',
  name: 'Phobos',
  kind: 'Moon of Mars',
  parentName: 'Mars',
  type: BodyType.rocky,
  colA: Color(0xFF8A7B6D),
  colB: Color(0xFF4A4038),
  atmo: Color(0xFFFFFFFF),
  accent: Color(0xFF8D7B6A),
  spin: 0.08,
  seed: 7.0,
  diameterKm: 22.5,
  short:
      'A small, lumpy moon racing around Mars three times a day, slowly '
      'spiralling inward.',
  discover:
      'Phobos is the larger and inner of Mars\' two moons. It orbits just '
      '6,000 km above the Martian surface, closer than any other moon to its '
      'planet, and completes an orbit in under eight hours.',
  sectionTitle: 'Doomed orbit',
  section:
      'Tidal forces are pulling Phobos about 2 metres closer to Mars every '
      'century. In some 50 million years it will either crash into the planet '
      'or break apart into a ring.',
  stats: [
    Stat('Diameter', '22.5', 'km'),
    Stat('From Mars', '9,376', 'km'),
    Stat('Orbit', '7.7', 'hours'),
    Stat('Gravity', '0.0057', 'm/s²'),
    Stat('Craters', 'Stickney', '9 km'),
    Stat('Discovered', '1877', ''),
  ],
  history: [
    Milestone('1877', 'Discovery', 'Asaph Hall spots both Martian moons from Washington.'),
    Milestone('1971', 'Mariner 9', 'First close-up images reveal a cratered, potato-shaped world.'),
    Milestone('1989', 'Phobos 2', 'A Soviet probe studies the moon before contact is lost.'),
    Milestone('2008', 'HiRISE', 'Mars Reconnaissance Orbiter captures sharp colour images.'),
  ],
  layers: [
    Layer('Regolith', 1.0, Color(0xFF8A7B6D)),
    Layer('Porous rock', 0.9, Color(0xFF5D4E43)),
  ],
);

const europa = Body(
  id: 'europa',
  name: 'Europa',
  kind: 'Moon of Jupiter',
  parentName: 'Jupiter',
  type: BodyType.icy,
  colA: Color(0xFFE9E1D3),
  colB: Color(0xFF9C5A3C),
  atmo: Color(0xFFDDE8FF),
  atmoStr: 0.15,
  accent: Color(0xFFD7CCC8),
  spin: 0.06,
  seed: 5.0,
  diameterKm: 3122,
  short:
      'An ice-shelled moon hiding a global ocean, one of the best places to '
      'search for life beyond Earth.',
  discover:
      'Europa is the smallest of Jupiter\'s four Galilean moons. Its bright '
      'surface of water ice is crossed by long reddish fractures, and beneath '
      'it lies a salty ocean holding more water than all of Earth\'s seas.',
  sectionTitle: 'Hidden ocean',
  section:
      'Jupiter\'s gravity flexes Europa as it orbits, heating its interior. '
      'That heat keeps a liquid ocean, perhaps 100 km deep, from freezing '
      'under the ice shell.',
  stats: [
    Stat('Diameter', '3,122', 'km'),
    Stat('From Jupiter', '671,000', 'km'),
    Stat('Orbit', '3.55', 'days'),
    Stat('Gravity', '1.31', 'm/s²'),
    Stat('Surface', '-160', '°C'),
    Stat('Ice shell', '15–25', 'km'),
  ],
  history: [
    Milestone('1610', 'Discovery', 'Galileo Galilei spots Europa among Jupiter\'s four bright moons.'),
    Milestone('1979', 'Voyager', 'Voyager images reveal a smooth surface criss-crossed by cracks.'),
    Milestone('1996', 'Galileo', 'Magnetic readings point to a salty ocean under the ice.'),
    Milestone('2024', 'Europa Clipper', 'NASA launches a dedicated mission to study the icy moon.'),
  ],
  layers: [
    Layer('Ice shell', 1.0, Color(0xFFE9E1D3)),
    Layer('Ocean', 0.97, Color(0xFF4FC3F7)),
    Layer('Rocky mantle', 0.9, Color(0xFF8D6E63)),
    Layer('Iron core', 0.4, Color(0xFFFFB74D)),
  ],
);

const titan = Body(
  id: 'titan',
  name: 'Titan',
  kind: 'Moon of Saturn',
  parentName: 'Saturn',
  type: BodyType.hazy,
  colA: Color(0xFFD99A45),
  colB: Color(0xFF8C5A22),
  atmo: Color(0xFFE8B163),
  atmoStr: 0.9,
  accent: Color(0xFFE0A15A),
  spin: 0.05,
  seed: 9.0,
  diameterKm: 5150,
  short:
      'Saturn\'s largest moon, wrapped in a thick orange haze, with rivers and '
      'lakes of liquid methane.',
  discover:
      'Titan is the only moon with a dense atmosphere and the only world '
      'besides Earth known to have stable liquid on its surface. Its seas are '
      'made not of water but of liquid methane and ethane.',
  sectionTitle: 'Methane weather',
  section:
      'On Titan, methane plays the role water plays on Earth: it forms clouds, '
      'falls as rain, carves river valleys and pools into lakes near the poles.',
  stats: [
    Stat('Diameter', '5,150', 'km'),
    Stat('From Saturn', '1.22M', 'km'),
    Stat('Orbit', '15.9', 'days'),
    Stat('Gravity', '1.35', 'm/s²'),
    Stat('Surface', '-179', '°C'),
    Stat('Pressure', '1.5×', 'Earth'),
  ],
  history: [
    Milestone('1655', 'Discovery', 'Christiaan Huygens finds Saturn\'s largest moon.'),
    Milestone('1980', 'Voyager 1', 'A flyby reveals an opaque nitrogen-rich atmosphere.'),
    Milestone('2005', 'Huygens', 'The probe parachutes through the haze and lands on Titan.'),
    Milestone('2028', 'Dragonfly', 'A rotorcraft lander is planned to launch toward Titan.'),
  ],
  layers: [
    Layer('Ice crust', 1.0, Color(0xFFD9B26F)),
    Layer('Subsurface ocean', 0.9, Color(0xFF4FC3F7)),
    Layer('High-pressure ice', 0.78, Color(0xFFB3E5FC)),
    Layer('Rocky core', 0.6, Color(0xFF8D6E63)),
  ],
);

const titania = Body(
  id: 'titania',
  name: 'Titania',
  kind: 'Moon of Uranus',
  parentName: 'Uranus',
  type: BodyType.icy,
  colA: Color(0xFFBDB6AF),
  colB: Color(0xFF6E625A),
  atmo: Color(0xFFFFFFFF),
  accent: Color(0xFFBCAAA4),
  spin: 0.06,
  seed: 11.0,
  diameterKm: 1578,
  short:
      'The largest moon of Uranus, a grey world of ice and rock scarred by '
      'enormous canyons.',
  discover:
      'Titania is made of roughly equal parts ice and rock. Huge fault canyons '
      'hundreds of kilometres long suggest its crust stretched and cracked as '
      'its interior froze.',
  sectionTitle: 'Named for a queen',
  section:
      'Uranus\' moons are named after characters from Shakespeare and Pope. '
      'Titania is the queen of the fairies in A Midsummer Night\'s Dream.',
  stats: [
    Stat('Diameter', '1,578', 'km'),
    Stat('From Uranus', '436,000', 'km'),
    Stat('Orbit', '8.7', 'days'),
    Stat('Gravity', '0.38', 'm/s²'),
    Stat('Surface', '-203', '°C'),
    Stat('Discovered', '1787', ''),
  ],
  history: [
    Milestone('1787', 'Discovery', 'William Herschel finds Titania and Oberon.'),
    Milestone('1986', 'Voyager 2', 'The only spacecraft visit images about 40% of the surface.'),
    Milestone('2001', 'Occultation', 'A passing star shows Titania has no substantial atmosphere.'),
  ],
  layers: [
    Layer('Icy crust', 1.0, Color(0xFFBDB6AF)),
    Layer('Rocky core', 0.66, Color(0xFF8D6E63)),
  ],
);

const triton = Body(
  id: 'triton',
  name: 'Triton',
  kind: 'Moon of Neptune',
  parentName: 'Neptune',
  type: BodyType.icy,
  colA: Color(0xFFE8D2CC),
  colB: Color(0xFF8C6B66),
  atmo: Color(0xFFCFE3FF),
  atmoStr: 0.12,
  accent: Color(0xFFE1BEE7),
  spin: 0.06,
  seed: 13.0,
  diameterKm: 2707,
  short:
      'A frozen captured world that orbits Neptune backwards, with geysers of '
      'nitrogen erupting from its surface.',
  discover:
      'Triton is the only large moon in the solar system that orbits opposite '
      'to its planet\'s rotation, a sign it was probably captured from the '
      'Kuiper belt. Its surface is one of the coldest ever measured.',
  sectionTitle: 'Ice geysers',
  section:
      'Voyager 2 saw dark plumes rising 8 km above Triton\'s surface. Sunlight '
      'warms nitrogen ice from below until it bursts out, carrying dust that '
      'falls back as long streaks.',
  stats: [
    Stat('Diameter', '2,707', 'km'),
    Stat('From Neptune', '354,800', 'km'),
    Stat('Orbit', '5.9', 'days'),
    Stat('Gravity', '0.78', 'm/s²'),
    Stat('Surface', '-235', '°C'),
    Stat('Direction', 'Retro', 'grade'),
  ],
  history: [
    Milestone('1846', 'Discovery', 'William Lassell finds Triton just 17 days after Neptune itself.'),
    Milestone('1989', 'Voyager 2', 'A flyby reveals active geysers and a young surface.'),
  ],
  layers: [
    Layer('Nitrogen ice', 1.0, Color(0xFFE8D2CC)),
    Layer('Water-ice mantle', 0.9, Color(0xFFB3E5FC)),
    Layer('Rocky core', 0.7, Color(0xFF8D6E63)),
  ],
);

const planets = <Body>[
  Body(
    id: 'mercury',
    name: 'Mercury',
    kind: 'Terrestrial planet',
    type: BodyType.mercury,
    colA: Color(0xFF9E958C),
    colB: Color(0xFF5C544D),
    atmo: Color(0xFFFFFFFF),
    accent: Color(0xFFA8A29E),
    spin: 0.08,
    seed: 1.0,
    orbitAu: 0.39,
    diameterKm: 4879,
    companion: sun,
    short:
        'The smallest planet and the closest to the Sun, a scorched, cratered '
        'world with almost no atmosphere.',
    discover:
        'Mercury is the smallest planet in the solar system and the nearest to '
        'the Sun. It whips around its orbit in just 88 days, faster than any '
        'other planet, which is why it was named after the swift Roman '
        'messenger god.',
    sectionTitle: 'Extremes',
    section:
        'With no atmosphere to trap heat, Mercury swings from 430 °C in daylight '
        'to −180 °C at night. Yet water ice survives in craters near its poles '
        'that never see sunlight.',
    stats: [
      Stat('Diameter', '4,879', 'km'),
      Stat('From Sun', '57.9M', 'km'),
      Stat('Year', '88', 'days'),
      Stat('Solar day', '176', 'days'),
      Stat('Gravity', '3.7', 'm/s²'),
      Stat('Moons', '0', ''),
    ],
    history: [
      Milestone('1631', 'Transit', 'Pierre Gassendi observes Mercury crossing the face of the Sun.'),
      Milestone('1974', 'Mariner 10', 'The first spacecraft to fly past Mercury maps nearly half of it.'),
      Milestone('2011', 'MESSENGER', 'The first orbiter maps the whole planet and finds polar ice.'),
      Milestone('2018', 'BepiColombo', 'A joint European–Japanese mission launches toward Mercury.'),
    ],
    layers: [
      Layer('Crust', 1.0, Color(0xFF9E958C)),
      Layer('Mantle', 0.95, Color(0xFF8D6E63)),
      Layer('Iron core', 0.85, Color(0xFFFFB74D)),
    ],
  ),
  Body(
    id: 'venus',
    name: 'Venus',
    kind: 'Terrestrial planet',
    type: BodyType.venus,
    colA: Color(0xFFE8CFA0),
    colB: Color(0xFFB8874B),
    atmo: Color(0xFFFFE2A8),
    atmoStr: 0.8,
    accent: Color(0xFFE8C27A),
    spin: 0.04,
    seed: 2.0,
    orbitAu: 0.72,
    diameterKm: 12104,
    companion: sun,
    short:
        'Earth\'s twin in size but a runaway greenhouse, hidden beneath '
        'endless clouds of sulphuric acid.',
    discover:
        'Venus is the second planet from the Sun and the hottest in the solar '
        'system. Its thick carbon-dioxide atmosphere traps heat so well that '
        'the surface is hot enough to melt lead, day and night.',
    sectionTitle: 'Backwards spin',
    section:
        'Venus spins slowly in the opposite direction to most planets. A single '
        'rotation takes 243 Earth days, longer than its 225-day year, so the '
        'Sun rises in the west.',
    stats: [
      Stat('Diameter', '12,104', 'km'),
      Stat('From Sun', '108.2M', 'km'),
      Stat('Year', '225', 'days'),
      Stat('Rotation', '243', 'days'),
      Stat('Surface', '464', '°C'),
      Stat('Pressure', '92×', 'Earth'),
    ],
    history: [
      Milestone('1610', 'Phases', 'Galileo sees Venus go through phases, supporting a Sun-centred system.'),
      Milestone('1962', 'Mariner 2', 'The first successful flyby of another planet.'),
      Milestone('1970', 'Venera 7', 'The first spacecraft to transmit from another planet\'s surface.'),
      Milestone('1990', 'Magellan', 'Radar maps 98% of the surface through the clouds.'),
    ],
    layers: [
      Layer('Crust', 1.0, Color(0xFFD7B98A)),
      Layer('Mantle', 0.95, Color(0xFF8D6E63)),
      Layer('Core', 0.5, Color(0xFFFFB74D)),
    ],
  ),
  Body(
    id: 'earth',
    name: 'Earth',
    kind: 'Terrestrial planet',
    type: BodyType.earth,
    colA: Color(0xFF1E5AA8),
    colB: Color(0xFF2E7D32),
    atmo: Color(0xFF6FB6FF),
    atmoStr: 0.9,
    accent: Color(0xFF3B82F6),
    spin: 0.1,
    seed: 0.0,
    orbitAu: 1.0,
    diameterKm: 12742,
    companion: moon,
    short:
        'Is the third planet from the Sun and the only object in the Universe '
        'known to harbor life.',
    discover:
        'Earth is the third planet from the Sun and the only astronomical '
        'object known to harbor life. About 71% of its surface is covered with '
        'water, and its atmosphere of nitrogen and oxygen shields life from '
        'harmful radiation.',
    sectionTitle: 'Formation',
    section:
        'Earth formed around 4.54 billion years ago from the disc of dust and '
        'gas around the young Sun. Its surface cooled into a crust, and oceans '
        'formed from water vapour and ice delivered by comets and asteroids.',
    stats: [
      Stat('Diameter', '12,742', 'km'),
      Stat('From Sun', '149.6M', 'km'),
      Stat('Year', '365.25', 'days'),
      Stat('Day', '24', 'hours'),
      Stat('Gravity', '9.81', 'm/s²'),
      Stat('Moons', '1', ''),
    ],
    history: [
      Milestone('1957', 'Sputnik 1', 'The first artificial satellite orbits Earth.'),
      Milestone('1961', 'Vostok 1', 'Yuri Gagarin becomes the first human in space.'),
      Milestone('1968', 'Earthrise', 'Apollo 8 photographs Earth rising over the Moon.'),
      Milestone('1998', 'ISS', 'The first module of the International Space Station is launched.'),
    ],
    layers: [
      Layer('Crust', 1.0, Color(0xFF6D9E58)),
      Layer('Mantle', 0.99, Color(0xFFE57B3C)),
      Layer('Outer core', 0.55, Color(0xFFFFB74D)),
      Layer('Inner core', 0.19, Color(0xFFFFF59D)),
    ],
  ),
  Body(
    id: 'mars',
    name: 'Mars',
    kind: 'Terrestrial planet',
    type: BodyType.mars,
    colA: Color(0xFFC1652F),
    colB: Color(0xFF6E3218),
    atmo: Color(0xFFFFB38A),
    atmoStr: 0.35,
    accent: Color(0xFFF26B3A),
    spin: 0.1,
    seed: 4.0,
    orbitAu: 1.52,
    diameterKm: 6779,
    companion: phobos,
    short:
        'The red planet: a cold desert world of rusty dust, ancient riverbeds '
        'and the tallest volcano in the solar system.',
    discover:
        'Mars is the fourth planet from the Sun. Iron oxide in its dust gives it '
        'a rusty red colour. It is home to Olympus Mons, a volcano nearly three '
        'times as tall as Mount Everest, and Valles Marineris, a canyon as long '
        'as the United States is wide.',
    sectionTitle: 'Water',
    section:
        'Dry riverbeds, deltas and minerals that form only in water show that '
        'Mars was once warmer and wetter. Today water survives as ice in its '
        'polar caps and just beneath the surface.',
    stats: [
      Stat('Diameter', '6,779', 'km'),
      Stat('From Sun', '227.9M', 'km'),
      Stat('Year', '687', 'days'),
      Stat('Day', '24.6', 'hours'),
      Stat('Gravity', '3.71', 'm/s²'),
      Stat('Moons', '2', ''),
    ],
    history: [
      Milestone('1965', 'Mariner 4', 'The first close-up photos of another planet.'),
      Milestone('1976', 'Viking 1', 'The first successful landing on Mars.'),
      Milestone('1997', 'Sojourner', 'The first wheeled rover explores Ares Vallis.'),
      Milestone('2021', 'Ingenuity', 'The first powered, controlled flight on another planet.'),
    ],
    layers: [
      Layer('Crust', 1.0, Color(0xFFC1652F)),
      Layer('Mantle', 0.97, Color(0xFF8D6E63)),
      Layer('Core', 0.54, Color(0xFFFFB74D)),
    ],
  ),
  Body(
    id: 'jupiter',
    name: 'Jupiter',
    kind: 'Gas giant',
    type: BodyType.jupiter,
    colA: Color(0xFFE9D8BC),
    colB: Color(0xFFA9714A),
    atmo: Color(0xFFF5DEB3),
    atmoStr: 0.35,
    accent: Color(0xFFD9A066),
    spin: 0.16,
    seed: 6.0,
    orbitAu: 5.2,
    diameterKm: 139820,
    companion: europa,
    short:
        'The king of the planets, a striped giant big enough to swallow every '
        'other planet combined.',
    discover:
        'Jupiter is the fifth planet from the Sun and the largest in the solar '
        'system, more than twice as massive as all the other planets put '
        'together. Its colourful bands are clouds of ammonia stretched by winds '
        'of over 500 km/h.',
    sectionTitle: 'Great Red Spot',
    section:
        'The Great Red Spot is a storm wider than Earth that has been raging '
        'for at least 190 years. It has been shrinking for over a century, but '
        'still dwarfs any storm on our planet.',
    stats: [
      Stat('Diameter', '139,820', 'km'),
      Stat('From Sun', '778.5M', 'km'),
      Stat('Year', '11.9', 'years'),
      Stat('Day', '9.9', 'hours'),
      Stat('Gravity', '24.8', 'm/s²'),
      Stat('Moons', '95+', ''),
    ],
    history: [
      Milestone('1610', 'Galilean moons', 'Galileo discovers Io, Europa, Ganymede and Callisto.'),
      Milestone('1973', 'Pioneer 10', 'The first spacecraft to fly past Jupiter.'),
      Milestone('1995', 'Galileo', 'The first Jupiter orbiter drops a probe into its atmosphere.'),
      Milestone('2016', 'Juno', 'Juno arrives to study the planet\'s interior and poles.'),
    ],
    layers: [
      Layer('Atmosphere', 1.0, Color(0xFFE9D8BC)),
      Layer('Liquid hydrogen', 0.95, Color(0xFFB0BEC5)),
      Layer('Metallic hydrogen', 0.8, Color(0xFF78909C)),
      Layer('Dilute core', 0.3, Color(0xFFFFB74D)),
    ],
  ),
  Body(
    id: 'saturn',
    name: 'Saturn',
    kind: 'Gas giant',
    type: BodyType.saturn,
    colA: Color(0xFFEBD9A9),
    colB: Color(0xFFBF9A5F),
    atmo: Color(0xFFF7E6B5),
    atmoStr: 0.3,
    accent: Color(0xFFE3C77E),
    ringIn: 1.25,
    ringOut: 2.3,
    ringTilt: 0.42,
    tilt: -0.32,
    spin: 0.15,
    seed: 8.0,
    orbitAu: 9.5,
    diameterKm: 116460,
    companion: titan,
    short:
        'The jewel of the solar system, circled by dazzling rings of ice and '
        'rock.',
    discover:
        'Saturn is the sixth planet from the Sun and the second largest. It is '
        'the least dense planet: made mostly of hydrogen and helium, it would '
        'float in a bathtub big enough to hold it.',
    sectionTitle: 'The rings',
    section:
        'Saturn\'s rings stretch up to 280,000 km from the planet yet are '
        'mostly only about ten metres thick. They are made of countless pieces '
        'of water ice, from specks of dust to chunks as big as houses.',
    stats: [
      Stat('Diameter', '116,460', 'km'),
      Stat('From Sun', '1.43B', 'km'),
      Stat('Year', '29.4', 'years'),
      Stat('Day', '10.7', 'hours'),
      Stat('Gravity', '10.4', 'm/s²'),
      Stat('Moons', '270+', ''),
    ],
    history: [
      Milestone('1610', 'Odd ears', 'Galileo sees strange bulges either side of Saturn.'),
      Milestone('1655', 'Rings & Titan', 'Huygens explains the rings and discovers Titan.'),
      Milestone('1979', 'Pioneer 11', 'The first spacecraft to fly past Saturn.'),
      Milestone('2004', 'Cassini', 'Cassini begins 13 years in orbit, ending with a dive in 2017.'),
    ],
    layers: [
      Layer('Atmosphere', 1.0, Color(0xFFEBD9A9)),
      Layer('Liquid hydrogen', 0.92, Color(0xFFB0BEC5)),
      Layer('Metallic hydrogen', 0.6, Color(0xFF78909C)),
      Layer('Rocky core', 0.25, Color(0xFFFFB74D)),
    ],
  ),
  Body(
    id: 'uranus',
    name: 'Uranus',
    kind: 'Ice giant',
    type: BodyType.uranus,
    colA: Color(0xFF9FDCE4),
    colB: Color(0xFF6FB7C7),
    atmo: Color(0xFFB8F1F7),
    atmoStr: 0.6,
    accent: Color(0xFF7DD3E0),
    ringIn: 1.6,
    ringOut: 2.0,
    ringTilt: 1.2,
    tilt: 1.35,
    spin: 0.1,
    seed: 10.0,
    orbitAu: 19.2,
    diameterKm: 50724,
    companion: titania,
    short:
        'A pale cyan ice giant that rolls around the Sun on its side.',
    discover:
        'Uranus is the seventh planet from the Sun. Methane in its atmosphere '
        'absorbs red light, giving it a calm blue-green colour. It was the '
        'first planet discovered with a telescope.',
    sectionTitle: 'Tipped over',
    section:
        'Uranus is tilted by about 98 degrees, probably after a collision with '
        'an Earth-sized object long ago. Each pole gets around 42 years of '
        'continuous sunlight followed by 42 years of darkness.',
    stats: [
      Stat('Diameter', '50,724', 'km'),
      Stat('From Sun', '2.87B', 'km'),
      Stat('Year', '84', 'years'),
      Stat('Day', '17.2', 'hours'),
      Stat('Tilt', '98', '°'),
      Stat('Moons', '28+', ''),
    ],
    history: [
      Milestone('1781', 'Discovery', 'William Herschel finds the first planet unknown to the ancients.'),
      Milestone('1977', 'Rings', 'Astronomers detect rings as Uranus passes in front of a star.'),
      Milestone('1986', 'Voyager 2', 'The only spacecraft visit, discovering ten new moons.'),
      Milestone('2023', 'Webb', 'The James Webb Space Telescope images its rings in infrared.'),
    ],
    layers: [
      Layer('Atmosphere', 1.0, Color(0xFF9FDCE4)),
      Layer('Icy mantle', 0.8, Color(0xFF4FC3F7)),
      Layer('Rocky core', 0.25, Color(0xFF8D6E63)),
    ],
  ),
  Body(
    id: 'neptune',
    name: 'Neptune',
    kind: 'Ice giant',
    type: BodyType.neptune,
    colA: Color(0xFF3557C9),
    colB: Color(0xFF6A8BEA),
    atmo: Color(0xFF6E9BFF),
    atmoStr: 0.6,
    accent: Color(0xFF3F5BD9),
    tilt: 0.2,
    spin: 0.12,
    seed: 12.0,
    orbitAu: 30.1,
    diameterKm: 49244,
    companion: triton,
    short:
        'The windiest world we know: a deep blue giant at the dark edge of the '
        'planetary system.',
    discover:
        'Neptune is the eighth and farthest known planet from the Sun. It was '
        'the first planet found by mathematics rather than observation, after '
        'astronomers noticed something was tugging on Uranus.',
    sectionTitle: 'Supersonic winds',
    section:
        'Despite receiving little sunlight, Neptune has the fastest winds in the '
        'solar system, reaching over 2,000 km/h. Dark storms the size of Earth '
        'come and go in its atmosphere.',
    stats: [
      Stat('Diameter', '49,244', 'km'),
      Stat('From Sun', '4.5B', 'km'),
      Stat('Year', '164.8', 'years'),
      Stat('Day', '16.1', 'hours'),
      Stat('Gravity', '11.2', 'm/s²'),
      Stat('Moons', '16', ''),
    ],
    history: [
      Milestone('1846', 'Discovery', 'Johann Galle finds Neptune where Le Verrier predicted it.'),
      Milestone('1846', 'Triton', 'William Lassell spots Neptune\'s largest moon 17 days later.'),
      Milestone('1989', 'Voyager 2', 'The only flyby reveals the Great Dark Spot.'),
      Milestone('2022', 'Webb', 'The James Webb Space Telescope captures its faint rings.'),
    ],
    layers: [
      Layer('Atmosphere', 1.0, Color(0xFF3557C9)),
      Layer('Icy mantle', 0.85, Color(0xFF4FC3F7)),
      Layer('Rocky core', 0.25, Color(0xFF8D6E63)),
    ],
  ),
];
