--
-- PostgreSQL database dump
--

-- Dumped from database version 14.4 (Debian 14.4-1.pgdg110+1)
-- Dumped by pg_dump version 14.4 (Debian 14.4-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: geo; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA geo;


ALTER SCHEMA geo OWNER TO postgres;

--
-- Name: music; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA music;


ALTER SCHEMA music OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: countries; Type: TABLE; Schema: geo; Owner: postgres
--

CREATE TABLE geo.countries (
    id_country character(32) NOT NULL,
    country character varying(100) NOT NULL,
    flag character(2)
);


ALTER TABLE geo.countries OWNER TO postgres;

--
-- Name: places; Type: TABLE; Schema: geo; Owner: postgres
--

CREATE TABLE geo.places (
    id_place character(32) NOT NULL,
    place character varying(100) NOT NULL
);


ALTER TABLE geo.places OWNER TO postgres;

--
-- Name: bands; Type: TABLE; Schema: music; Owner: postgres
--

CREATE TABLE music.bands (
    id_band character(32) NOT NULL,
    band character varying(100) NOT NULL,
    likes character(1),
    CONSTRAINT bands_likes_check CHECK ((likes = ANY (ARRAY['y'::bpchar, 'n'::bpchar, 'm'::bpchar])))
);


ALTER TABLE music.bands OWNER TO postgres;

--
-- Name: bands_countries; Type: TABLE; Schema: music; Owner: postgres
--

CREATE TABLE music.bands_countries (
    id_band character(32) NOT NULL,
    id_country character(32) NOT NULL
);


ALTER TABLE music.bands_countries OWNER TO postgres;

--
-- Name: bands_events; Type: TABLE; Schema: music; Owner: postgres
--

CREATE TABLE music.bands_events (
    id_band character(32) NOT NULL,
    id_event character(32) NOT NULL
);


ALTER TABLE music.bands_events OWNER TO postgres;

--
-- Name: bands_generes; Type: TABLE; Schema: music; Owner: postgres
--

CREATE TABLE music.bands_generes (
    id_band character(32) NOT NULL,
    id_genere character(32) NOT NULL
);


ALTER TABLE music.bands_generes OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: music; Owner: postgres
--

CREATE TABLE music.events (
    id_event character(32) NOT NULL,
    event character varying(255) NOT NULL,
    date_event date NOT NULL,
    id_place character(32) NOT NULL
);


ALTER TABLE music.events OWNER TO postgres;

--
-- Name: generes; Type: TABLE; Schema: music; Owner: postgres
--

CREATE TABLE music.generes (
    id_genere character(32) NOT NULL,
    genere character varying(100) NOT NULL
);


ALTER TABLE music.generes OWNER TO postgres;

--
-- Name: mv_musical_info; Type: MATERIALIZED VIEW; Schema: music; Owner: postgres
--

CREATE MATERIALIZED VIEW music.mv_musical_info AS
 SELECT b.band,
    b.likes,
    c.country,
    c.flag,
    g.genere,
    e.event,
    e.date_event,
    p.place
   FROM (((((((music.bands b
     JOIN music.bands_countries bc ON ((b.id_band = bc.id_band)))
     JOIN geo.countries c ON ((c.id_country = bc.id_country)))
     JOIN music.bands_generes bg ON ((b.id_band = bg.id_band)))
     JOIN music.generes g ON ((g.id_genere = bg.id_genere)))
     JOIN music.bands_events be ON ((be.id_band = b.id_band)))
     JOIN music.events e ON ((e.id_event = be.id_event)))
     JOIN geo.places p ON ((p.id_place = e.id_place)))
  ORDER BY b.band
  WITH NO DATA;


ALTER TABLE music.mv_musical_info OWNER TO postgres;

--
-- Name: v_bands; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_bands AS
 SELECT b.id_band,
    b.band,
    c.country,
    c.flag,
    b.likes,
    count(DISTINCT bg.id_genere) AS generes,
    count(DISTINCT be.id_event) AS events
   FROM ((((music.bands b
     JOIN music.bands_countries bc ON ((b.id_band = bc.id_band)))
     JOIN geo.countries c ON ((c.id_country = bc.id_country)))
     JOIN music.bands_generes bg ON ((bg.id_band = b.id_band)))
     JOIN music.bands_events be ON ((be.id_band = b.id_band)))
  GROUP BY b.id_band, b.band, c.country, c.flag, b.likes
  ORDER BY b.band;


ALTER TABLE music.v_bands OWNER TO postgres;

--
-- Name: v_bands_events; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_bands_events AS
 SELECT b.id_band,
    b.band,
    e.event
   FROM ((music.bands b
     JOIN music.bands_events be ON ((b.id_band = be.id_band)))
     JOIN music.events e ON ((be.id_event = e.id_event)))
  ORDER BY b.band;


ALTER TABLE music.v_bands_events OWNER TO postgres;

--
-- Name: v_bands_generes; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_bands_generes AS
 SELECT b.id_band,
    b.band,
    g.genere
   FROM ((music.bands b
     JOIN music.bands_generes bg ON ((b.id_band = bg.id_band)))
     JOIN music.generes g ON ((bg.id_genere = g.id_genere)))
  ORDER BY b.band;


ALTER TABLE music.v_bands_generes OWNER TO postgres;

--
-- Name: v_bands_likes; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_bands_likes AS
 SELECT bands.likes,
    count(bands.id_band) AS bands
   FROM music.bands
  GROUP BY bands.likes
  ORDER BY (count(bands.id_band)) DESC;


ALTER TABLE music.v_bands_likes OWNER TO postgres;

--
-- Name: v_countries; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_countries AS
 SELECT c.id_country,
    c.country,
    c.flag,
    count(DISTINCT bc.id_band) AS bands
   FROM (geo.countries c
     JOIN music.bands_countries bc ON ((c.id_country = bc.id_country)))
  GROUP BY c.country, c.flag, c.id_country
  ORDER BY (count(DISTINCT bc.id_band)) DESC;


ALTER TABLE music.v_countries OWNER TO postgres;

--
-- Name: v_events; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_events AS
 SELECT e.id_event,
    date_part('year'::text, e.date_event) AS year,
    ((((
        CASE
            WHEN (date_part('day'::text, e.date_event) < (10)::double precision) THEN ('0'::text || (date_part('day'::text, e.date_event))::text)
            ELSE (date_part('day'::text, e.date_event))::text
        END || '.'::text) ||
        CASE
            WHEN (date_part('month'::text, e.date_event) < (10)::double precision) THEN ('0'::text || (date_part('month'::text, e.date_event))::text)
            ELSE (date_part('month'::text, e.date_event))::text
        END) || '.'::text) || date_part('year'::text, e.date_event)) AS date,
    e.event,
    p.place,
    count(DISTINCT be.id_band) AS bands
   FROM ((music.events e
     JOIN geo.places p ON ((p.id_place = e.id_place)))
     JOIN music.bands_events be ON ((be.id_event = e.id_event)))
  GROUP BY e.event, p.place, e.date_event, e.id_event
  ORDER BY e.date_event;


ALTER TABLE music.v_events OWNER TO postgres;

--
-- Name: v_events_years; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_events_years AS
 SELECT date_part('year'::text, events.date_event) AS years,
    count(events.id_event) AS events
   FROM music.events
  GROUP BY (date_part('year'::text, events.date_event))
  ORDER BY (date_part('year'::text, events.date_event));


ALTER TABLE music.v_events_years OWNER TO postgres;

--
-- Name: v_generes; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_generes AS
 SELECT g.id_genere,
    g.genere,
    count(bg.id_band) AS bands
   FROM (music.generes g
     JOIN music.bands_generes bg ON ((g.id_genere = bg.id_genere)))
  GROUP BY g.genere, g.id_genere
  ORDER BY (count(bg.id_band)) DESC;


ALTER TABLE music.v_generes OWNER TO postgres;

--
-- Name: v_places_events; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_places_events AS
 SELECT gp.id_place,
    gp.place,
    count(e.id_event) AS events
   FROM (geo.places gp
     JOIN music.events e ON ((e.id_place = gp.id_place)))
  GROUP BY gp.place, gp.id_place
  ORDER BY (count(e.id_event)) DESC;


ALTER TABLE music.v_places_events OWNER TO postgres;

--
-- Name: v_quantities; Type: VIEW; Schema: music; Owner: postgres
--

CREATE VIEW music.v_quantities AS
 SELECT 'bands'::text AS entities,
    count(*) AS quantity
   FROM music.bands
UNION
 SELECT 'events'::text AS entities,
    count(*) AS quantity
   FROM music.events
UNION
 SELECT 'places'::text AS entities,
    count(*) AS quantity
   FROM geo.places
UNION
 SELECT 'generes'::text AS entities,
    count(*) AS quantity
   FROM music.generes;


ALTER TABLE music.v_quantities OWNER TO postgres;

--
-- Data for Name: countries; Type: TABLE DATA; Schema: geo; Owner: postgres
--

COPY geo.countries (id_country, country, flag) FROM stdin;
00247297c394dd443dc97067830c35f4	Slovenia	si
0309a6c666a7a803fdb9db95de71cf01	France	fr
06630c890abadde9228ea818ce52b621	Luxembourg	lu
0c7d5ae44b2a0be9ebd7d6b9f7d60f20	Romania	ro
1007e1b7f894dfbf72a0eaa80f3bc57e	Italy	it
21fc68909a9eb8692e84cf64e495213e	Iran	ir
2e6507f70a9cc26fb50f5fd82a83c7ef	Chile	cl
2ff6e535bd2f100979a171ad430e642b	Serbia	rs
33cac763789c407f405b2cf0dce7df89	Cuba	cu
3536be57ce0713954e454ae6c53ec023	Argentina	ar
3ad08396dc5afa78f34f548eea3c1d64	Switzerland	ch
424214945ba5615eca039bfe5d731c09	Denmark	dk
42537f0fb56e31e20ab9c2305752087d	Brazil	br
4442e4af0916f53a07fb8ca9a49b98ed	Australia	au
445d337b5cd5de476f99333df6b0c2a7	Canada	ca
4647d00cf81f8fb0ab80f753320d0fc9	Indonesia	id
51802d8bb965d0e5be697f07d16922e8	Czech Republic	cz
53a577bb3bc587b0c28ab808390f1c9b	Japan	jp
5882b568d8a010ef48a6896f53b6eddb	Costa Rica	cr
5feb168ca8fb495dcc89b1208cdeb919	Russia	ru
6542f875eaa09a5c550e5f3986400ad9	Belarus	by
6b718641741f992e68ec3712718561b8	Greece	gr
6bec347f256837d3539ad619bd489de7	Panama	pa
6c1674d14bf5f95742f572cddb0641a7	Belgium	be
6f781c6559a0c605da918096bdb69edf	Finland	fi
76423d8352c9e8fc8d7d65f62c55eae9	UK	gb
8189ecf686157db0c0274c1f49373318	International	un
8dbb07a18d46f63d8b3c8994d5ccc351	Mexico	mx
907eba32d950bfab68227fd7ea22999b	Spain	es
94880bda83bda77c5692876700711f15	Poland	pl
9891739094756d2605946c867b32ad28	Austria	at
a67d4cbdd1b59e0ffccc6bafc83eb033	Netherlands	nl
ae54a5c026f31ada088992587d92cb3a	China	cn
b78edab0f52e0d6c195fd0d8c5709d26	Iceland	is
c51ed580ea5e20c910d951f692512b4d	New Zealand	nz
c8f4261f9f46e6465709e17ebea7a92b	Sweden	se
d5b9290a0b67727d4ba1ca6059dc31a6	Norway	no
d8b00929dec65d422303256336ada04f	Germany	de
ea71b362e3ea9969db085abfccdeb10d	Portugal	pt
ef3388cc5659bccb742fb8af762f1bfd	Colombia	co
f01fc92b23faa973f3492a23d5a705c5	Ukraine	ua
f75d91cdd36b85cc4a8dfeca4f24fa14	USA	us
fa79c3005daec47ecff84a116a0927a1	Hungary	hu
\.


--
-- Data for Name: places; Type: TABLE DATA; Schema: geo; Owner: postgres
--

COPY geo.places (id_place, place) FROM stdin;
875ec5037fe25fad96113c57da62f9fe	Landau (Gloria Kulturpalast)
8bb89006a86a427f89e49efe7f1635c1	Mainz (Alexander the Great)
2a8f2b9aef561f19faad529d927dba17	Offenbach (Stadthalle)
c6e9ff60da2342ba2a0ce4d9b6fc6ff1	Aschaffenburg (Colos-Saal)
741ae9098af4e50aecf13b0ef08ecc47	Barleben
beeb45e34fe94369bed94ce75eb1e841	Lichtenfels (Stadhalle)
0b186d7eb0143e60ced4af3380f5faa8	Weinheim (Caf?? Central)
620f9da22d73cc8d5680539a4c87402b	Mainz (M8 im Haus der Jugend)
4e637199a58a4ff2ec4b956d06e472e8	Worms (Schwarzer B??r)
2b18765ced0c329ecd1f1663925e8342	Mannheim (7er-Club)
828d35ecd5412f7bc1ba369d5d657f9f	Heidelberg (halle 02)
fd4c04c6fadcc6eafbc12e81374bca85	Frankfurt (Das Bett)
858d53d9bd193393481e4e8b24d10bba	Aschaffenburg (JUKUZ)
19a1767aab9e93163ad90f2dfe82ec71	Mainz (Rheinhufer)
4e592038a4c7b6cdc3e7b92d98867506	Frankfurt am Main (Nachtleben)
29ae00a7e41558eb2ed8c0995a702d7a	Mainz (Alte Ziegelei)
1e9e26a0456c1694d069e119dae54240	Oberursel
38085fa2d02ff7710a42a0c61ab311e2	Offenbach (Capitol)
d1ad016a5b257743ef75594c67c52935	R??sselsheim (Das Rind)
d379f693135eefa77bc9732f97fcaaf1	Hockenheim (Hockenheim-Ring)
b67af931a5d0322adc7d56846dca86dc	Leipzig (Felsenkeller / Naumanns)
7adc966f52e671b15ea54075581c862b	Schriesheim
427a371fadd4cce654dd30c27a36acb0	Wiesbaden (Schlachthof)
44e48d95c27db0d3558a072c139d2761	Frankfurt (Jarhunderthalle)
f3c1ffc50f4f8d0a857533164e8da867	Mainz (KUZ - Kulturzentrum)
e74b09ddc9ecbc635ae3ce58a4cddd59	Frankfurt (Festhalle)
4751a5b2d9992dca6e462e3b14695284	Mannheim (MS Connexion Complex)
d5c76ce146e0b3f46e69e870e9d48181	Rockenhausen
59c2a4862605f1128b334896c17cab7b	Magdeburg (Factory)
3b0409f1b5830369aac22e3c5b9b9815	Ballenstedt
55ff4adc7d421cf9e05b68d25ee22341	Mainz-Kastel (Reduit)
bb1bac023b4f02a5507f1047970d1aca	Neuborn
21760b1bbe36b4dae8fa9e0c274f76bf	Mannheim (Maimarkt)
50bd324043e0b113bea1b5aa0422806f	Neckargem??nd (Metal Club Odinwald)
7786a0fc094d859eb469868003b142db	Mannheim (SAP Arena)
657d564cc1dbaf58e2f2135b57d02d99	Bad Kreuznach (Jakob-Kiefer-Halle)
41b6f7fdc3453cc5f989c347d9b4b674	Havana (Sala Maxim Rock)
012d8da36e8518d229988fe061f3c376	Ulm (Hexenhaus)
14b82c93c42422209e5b5aad5b7b772e	Mainz (Kulturcaf?? auf dem Campus)
3611a0c17388412df8e42cf1858d5e99	Kaiserslautern (Irish House)
99d75d9948711c04161016c0d2280dd9	Bonn (Bla)
2898437c2420ae271ae3310552ad6d70	Darmstadt (Goldene Krone)
871568e58a911610979cadc2c1e94122	Hirschaid
6d998a5f2c8b461a654f7f9e34ab4368	Lindau (Club Vaudeville)
\.


--
-- Data for Name: bands; Type: TABLE DATA; Schema: music; Owner: postgres
--

COPY music.bands (id_band, band, likes) FROM stdin;
8b427a493fc39574fc801404bc032a2f	1000Mods	y
721c28f4c74928cc9e0bb3fef345e408	Aborted	y
0a7ba3f35a9750ff956dca1d548dad12	Abrogation	y
54b72f3169fea84731d3bcba785eac49	Acranius	y
d05a0e65818a69cc689b38c0c0007834	ADDICT	y
dcabc7299e2b9ed5b05c33273e5fdd19	Aeon of Disease	y
5ce10014f645da4156ddd2cd0965986e	Agnostic Front	y
a332f1280622f9628fccd1b7aac7370a	Agrypnie	y
249789ae53c239814de8e606ff717ec9	Airborn	m
b1bdad87bd3c4ac2c22473846d301a9e	Al Goregrind	m
fe5b73c2c2cd2d9278c3835c791289b6	All its Grace	y
942c9f2520684c22eb6216a92b711f9e	Amon Amarth	y
7cd7921da2e6aab79c441a0c2ffc969b	Amorphis	y
948098e746bdf1c1045c12f042ea98c2	Analepsy	y
59d153c1c2408b702189623231b7898a	Angelus Apatrida	y
06efe152a554665e02b8dc4f620bf3f1	Anthrax	y
14ab730fe0172d780da6d9e5d432c129	AntiPeeWee	m
449b4d758aa7151bc1bbb24c3ffb40bb	Anubis	m
5df92b70e2855656e9b3ffdf313d7379	An??s	y
3e75cd2f2f6733ea4901458a7ce4236d	Apey & The Pea	n
108c58fc39b79afc55fac7d9edf4aa2a	Arch Enemy	y
28bc31b338dbd482802b77ed1fd82a50	Arroganz	y
49c4097bae6c6ea96f552e38cfb6c2d1	Artillery	n
e3f0bf612190af6c3fad41214115e004	Asomvel	y
fb47f889f2c7c4fee1553d0f817b8aaa	Asphyx	y
264721f3fc2aee2d28dadcdff432dbc1	Atomwinter	m
9a322166803a48932356586f05ef83c7	At the Gates	y
75ab0270163731ee05f35640d56ef473	Audrey Horne	m
9d3ac6904ce73645c6234803cd7e47ca	Au??erwelt	y
d1fb4e47d8421364f49199ee395ad1d3	Aversions Crown	y
44012166c6633196dc30563db3ffd017	Avowal	y
905a40c3533830252a909603c6fa1e6a	Avulsed	y
aed85c73079b54830cd50a75c0958a90	Baleful Abyss (Zombieslut)	y
da2110633f62b16a571c40318e4e4c1c	Battle against the Empire	y
529a1d385b4a8ca97ea7369477c7b6a7	Battle Beast	m
ce2caf05154395724e4436f042b8fa53	Begging for Incest	m
be20385e18333edb329d4574f364a1f0	Behemoth	y
ee69e7d19f11ca58843ec2e9e77ddb38	Benediction	y
925bd435e2718d623768dbf1bc1cfb60	Benighted	y
ad01952b3c254c8ebefaf6f73ae62f7d	Betrayal	y
7c7ab6fbcb47bd5df1e167ca28220ee9	Betraying the Martyrs	m
e8afde257f8a2cbbd39d866ddfc06103	Bitchfork	y
8f1f10cb698cb995fd69a671af6ecd58	Black Crown Initiate	y
bbddc022ee323e0a2b2d8c67e5cd321f	Black Medusa	y
74b3b7be6ed71b946a151d164ad8ede5	Black Reunion	y
d9ab6b54c3bd5b212e8dc3a14e7699ef	Bl??ck Fox	y
679eaa47efb2f814f2642966ee6bdfe1	Blessed Hellride	y
e1db3add02ca4c1af33edc5a970a3bdc	Blizzen	m
1c6987adbe5ab3e4364685e8caed0f59	Bloodbound	y
cf4ee20655dd3f8f0a553c73ffe3f72a	Blood Fire Death	y
348bcdb386eb9cb478b55a7574622b7c	Bloodgod	y
b3ffff8517114caf70b9e70734dbaf6f	Bloodred Hourglass	y
a4cbfb212102da21b82d94be555ac3ec	Blood Red Throne	y
10d91715ea91101cfe0767c812da8151	Bloodspot	y
1209f43dbecaba22f3514bf40135f991	Bobby Sixkiller and the Renegades	y
dcff9a127428ffb03fc02fdf6cc39575	B??hse Onkelz	m
6c00bb1a64f660600a6c1545377f92dc	Bokassa	y
55159d04cc4faebd64689d3b74a94009	Booze & Glory	m
b6da055500e3d92698575a3cfc74906c	Born from Pain	m
1e9413d4cc9af0ad12a6707776573ba0	B??sedeath	y
b01fbaf98cfbc1b72e8bca0b2e48769c	Bowel Evacuation	y
4b98a8c164586e11779a0ef9421ad0ee	Brainstorm	m
897edb97d775897f69fa168a88b01c19	Brand of Sacrifice	y
eeaeec364c925e0c821660c7a953546e	Broken Teeth	m
7533f96ec01fd81438833f71539c7d4e	Bullet	m
11635778f116ce6922f6068638a39028	Burn	m
d449a9b2eed8b0556dc7be9cda36b67b	Bury Tomorrow	y
7eaf9a47aa47f3c65595ae107feab05d	Caliban	y
7463543d784aa59ca86359a50ef58c8e	Cancer	y
c4f0f5cedeffc6265ec3220ab594d56b	Candlemass	m
63bd9a49dd18fbc89c2ec1e1b689ddda	Cannibal Corpse	y
63ae1791fc0523f47bea9485ffec8b8c	Carach Angren	y
c4c7cb77b45a448aa3ca63082671ad97	Carnal Decay	y
5435326cf392e2cd8ad7768150cd5df6	Carnation	y
828d51c39c87aad9b1407d409fa58e36	CCCP	y
d2ff1e521585a91a94fb22752dd0ab45	Chapel of Disease	y
77f2b3ea9e4bd785f5ff322bae51ba07	Children of Bodom	y
6f199e29c5782bd05a4fef98e7e41419	Circle of Execution	y
b0ce1e93de9839d07dab8d268ca23728	Colours of Autumn	m
6830afd7158930ca7d1959ce778eb681	Combichrist	y
a61b878c2b563f289de2109fa0f42144	Conan	m
e67e51d5f41cfc9162ef7fd977d1f9f5	Condemned	y
3d2ff8abd980d730b2f4fd0abae52f60	Converge	m
ffa7450fd138573d8ae665134bccd02c	Corpsessed	y
faabbecd319372311ed0781d17b641d1	Counterparts	m
9f19396638dd8111f2cee938fdf4e455	Critical Mess	y
fdcbfded0aaf369d936a70324b39c978	Crossplane	y
47b23e889175dde5d6057db61cb52847	Crowbar	m
1056b63fdc3c5015cc4591aa9989c14f	Crusher	y
b5d9c5289fe97968a5634b3e138bf9e2	Cryptopsy	y
2876f7ecdae220b3c0dcb91ff13d0590	Ctulu	y
1734b04cf734cb291d97c135d74b4b87	Cytotoxin	y
7d6b45c02283175f490558068d1fc81b	Dagoba	y
8d7a18d54e82fcfb7a11566ce94b9109	Daily Insanity	y
dddb04bc0d058486d0ef0212c6ea0682	Darkall Slaves	y
0e2ea6aa669710389cf4d6e2ddf408c4	Darkened Nocturn Slaughtercult	y
63ad3072dc5472bb44c2c42ede26d90f	Darkness	m
2aae4f711c09481c8353003202e05359	Dark Zodiak	y
28f843fa3a493a3720c4c45942ad970e	Dawn of Disease	y
9bc2ca9505a273b06aa0b285061cd1de	Dead Congregation	y
d3ed8223151e14b936436c336a4c7278	Batushka	y
51fa80e44b7555c4130bd06c53f4835c	Cradle of Filth	y
9138c2cc0326412f2515623f4c850eb3	Dead Eyed Sleeper (Legacy)	y
44b7bda13ac1febe84d8607ca8bbf439	Death Angel	y
d857ab11d383a7e4d4239a54cbf2a63d	Deathrite	y
c74b5aa120021cbe18dcddd70d8622da	Deathstorm	y
3af7c6d148d216f13f66669acb8d5c59	Debauchery's Balgeroth	y
522b6c44eb0aedf4970f2990a2f2a812	Decapitated	y
f4219e8fec02ce146754a5be8a85f246	Decaying Days	y
c5f022ef2f3211dc1e3b8062ffe764f0	Defaced	y
0ab20b5ad4d15b445ed94fa4eebb18d8	Defocus	y
7fc454efb6df96e012e0f937723d24aa	Demored	y
8edfa58b1aedb58629b80e5be2b2bd92	Denyal	y
8589a6a4d8908d7e8813e9a1c5693d70	Depulsed	y
947ce14614263eab49f780d68555aef8	Deranged	y
7c83727aa466b3b1b9d6556369714fcf	Desbroce	y
71e32909a1bec1edfc09aec09ca2ac17	Desdemonia	y
3d01ff8c75214314c4ca768c30e6807b	Deserted Fear	y
7771012413f955f819866e517b275cb4	Destinity	y
36f969b6aeff175204078b0533eae1a0	Destr??yer 666	y
1bc1f7348d79a353ea4f594de9dd1392	Devil Driver	y
2082a7d613f976e7b182a3fe80a28958	Dimmu Borgir	y
d9bc1db8c13da3a131d853237e1f05b2	Disbelief	y
9cf73d0300eea453f17c6faaeb871c55	Discreation	m
4dddd8579760abb62aa4b1910725e73c	Disquiet	m
d6de9c99f5cfa46352b2bc0be5c98c41	Dissecdead	y
5194c60496c6f02e8b169de9a0aa542c	Double Crush Syndrome	m
8654991720656374d632a5bb0c20ff11	Downfall of Gaia	m
6a0e9ce4e2da4f2cbcd1292fddaa0ac6	Down to Nothing	m
fe228019addf1d561d0123caae8d1e52	Dragonsfire	n
1104831a0d0fe7d2a6a4198c781e0e0d	Dust Bolt	y
889aaf9cd0894206af758577cf5cf071	Dyscarnate	y
410d913416c022077c5c1709bf104d3c	EDGEBALL	n
c5dc33e23743fb951b3fe7f1f477b794	Einherjer	y
97ee29f216391d19f8769f79a1218a71	Eisregen	y
b885447285ece8226facd896c04cdba2	Ektomorf	y
3614c45db20ee41e068c2ab7969eb3b5	Ellende	n
c4ddbffb73c1c34d20bd5b3f425ce4b1	Elvenking	y
f07c3eef5b7758026d45a12c7e2f6134	Embrace Decay	y
9d969d25c9f506c5518bb090ad5f8266	Embryectomy	m
0b6e98d660e2901c33333347da37ad36	Emerald	n
6d3b28f48c848a21209a84452d66c0c4	Eminenz	y
8c69497eba819ee79a964a0d790368fb	Endlevel	y
1197a69404ee9475146f3d631de12bde	End of Green	y
d730e65d54d6c0479561d25724afd813	Enforcer	n
457f098eeb8e1518008449e9b1cb580d	Enisum	y
ac94d15f46f10707a39c4bc513cd9f98	Enterprise Earth	y
37f02eba79e0a3d29dfd6a4cf2f4d019	Epica	n
39e83bc14e95fcbc05848fc33c30821f	Epicardiectomy	y
f0c051b57055b052a3b7da1608f3039e	Eradicator	m
e08383c479d96a8a762e23a99fd8bf84	Ereb Altor	m
ff5b48d38ce7d0c47c57555d4783a118	Evertale	m
8945663993a728ab19a3853e5b820a42	Evil Invaders	y
28a95ef0eabe44a27f49bbaecaa8a847	Exhorder	y
0cdf051c93865faa15cbc5cd3d2b69fb	Exodus	y
ade72e999b4e78925b18cf48d1faafa4	Exorcised Gods	n
4b503a03f3f1aec6e5b4d53dd8148498	Extermination Dismemberment	y
887d6449e3544dca547a2ddba8f2d894	Exumer	y
2672777b38bc4ce58c49cf4c82813a42	Fallen Temple	y
832dd1d8efbdb257c2c7d3e505142f48	Far from ready	m
f37ab058561fb6d233b9c2a0b080d4d1	Feuerschwanz	y
3be3e956aeb5dc3b16285463e02af25b	Finsterforst	y
42563d0088d6ac1a47648fc7621e77c6	Firtan	y
7df8865bbec157552b8a579e0ed9bfe3	Five Finger Death Punch	y
c883319a1db14bc28eff8088c5eba10e	Fjoergyn	y
6b7cf117ecf0fea745c4c375c1480cb5	Fleshcrawl	y
187ebdf7947f4b61e0725c93227676a4	Fleshgod Apocalypse	y
4276250c9b1b839b9508825303c5c5ae	Fleshsphere	y
7462f03404f29ea618bcc9d52de8e647	Flesh Trading Company	y
5efb7d24387b25d8325839be958d9adf	Fracture	m
9db9bc745a7568b51b3a968d215ddad6	From North	m
cddf835bea180bd14234a825be7a7a82	Funeral Whore	y
fdc90583bd7a58b91384dea3d1659cde	Furies	n
401357e57c765967393ba391a338e89b	Ghost	y
e64b94f14765cee7e05b4bec8f5fee31	Gingerpig	m
d0a1fd0467dc892f0dc27711637c864e	God Dethroned	y
e271e871e304f59e62a263ffe574ea2d	GodSkill	y
a8d9eeed285f1d47836a5546a280a256	Godslave	y
abbf8e3e3c3e78be8bd886484c1283c1	Grabak	y
87f44124fb8d24f4c832138baede45c7	Grand Magus	y
ed24ff8971b1fa43a1efbb386618ce35	Grave	y
33b6f1b596a60fa87baef3d2c05b7c04	Grave Pleasures	m
426fdc79046e281c5322161f011ce68c	Graveyard	y
988d10abb9f42e7053450af19ad64c7f	Gut	n
dd18fa7a5052f2bce8ff7cb4a30903ea	Gutalax	n
b89e91ccf14bfd7f485dd7be7d789b0a	H2O	m
87ded0ea2f4029da0a0022000d59232b	Hadal Maw	m
2a024edafb06c7882e2e1f7b57f2f951	Hailstone	m
2fa2f1801dd37d6eb9fe4e34a782e397	H??matom	y
e0c2b0cc2e71294cd86916807fef62cb	Hammer King	m
52ee4c6902f6ead006b0fb2f3e2d7771	H??ngerb??nd	y
4f48e858e9ed95709458e17027bb94bf	Hark	y
e0de9c10bbf73520385ea5dcbdf62073	Hatebreed	y
065b56757c6f6a0fba7ab0c64e4c1ae1	Hate Eternal	y
952dc6362e304f00575264e9d54d1fa6	Haunted Cemetery	y
5cd1c3c856115627b4c3e93991f2d9cd	Havok	y
0903a7e60f0eb20fdc8cc0b8dbd45526	Hell Boullevard	y
32af59a47b8c7e1c982ae797fc491180	Hellknife	y
fb8be6409408481ad69166324bdade9c	Hell:On	y
bd4184ee062e4982b878b6b188793f5b	Hellripper	y
0020f19414b5f2874a0bfacd9d511b84	Helrunar	y
de12bbf91bc797df25ab4ae9cee1946b	Hexenizer	y
237e378c239b44bff1e9a42ab866580c	Hierophant	y
89adcf990042dfdac7fd23685b3f1e37	High Fighter	m
44f2dc3400ce17fad32a189178ae72fa	Hills have Eyes	m
3bd94845163385cecefc5265a2e5a525	Hollowed	y
0b0d1c3752576d666c14774b8233889f	Hollow World	m
a4902fb3d5151e823c74dfd51551b4b0	Horisont	m
99bd5eff92fc3ba728a9da5aa1971488	Horresque	y
24ff2b4548c6bc357d9d9ab47882661e	Humator	y
776da10f7e18ffde35ea94d144dc60a3	Hypocrisy	y
829922527f0e7d64a3cfda67e24351e3	Ichor	y
bfc9ace5d2a11fae56d038d68c601f00	I Declare War	y
443866d78de61ab3cd3e0e9bf97a34f6	Igel vs. Shark	m
b570e354b7ebc40e20029fcc7a15e5a7	Ignite	n
7492a1ca2669793b485b295798f5d782	I'll be damned	m
63d7f33143522ba270cb2c87f724b126	Illdisposed	y
aa86b6fc103fc757e14f03afe6eb0c0a	Imperium Dekadenz	y
6c607fc8c0adc99559bc14e01170fee1	Incite	m
91a337f89fe65fec1c97f52a821c1178	Inconcessus Lux Lucis	y
5ec1e9fa36898eaf6d1021be67e0d00c	Indian Nightmare	n
8ce896355a45f5b9959eb676b8b5580c	Infected World	m
bbce8e45250a239a252752fac7137e00	In Flames	y
baa9d4eef21c7b89f42720313b5812d4	Ingested	y
2414366fe63cf7017444181acacb6347	Inhumate	y
1ac0c8e8c04cf2d6f02fdb8292e74588	Insanity Alert	m
5f992768f7bb9592bed35b07197c87d0	Insulter	m
ca5a010309ffb20190558ec20d97e5b2	In the Woods	n
f644bd92037985f8eb20311bc6d5ed94	Into Darkness	y
a825b2b87f3b61c9660b81f340f6e519	Iron Bastards	m
891a55e21dfacf2f97c450c77e7c3ea7	Iron Reagan	y
ef6369d9794dbe861a56100e92a3c71d	Isole	m
73affe574e6d4dc2fa72b46dc9dd4815	Jinjer	n
649db5c9643e1c17b3a44579980da0ad	Kaasschaaf	y
1e8563d294da81043c2772b36753efaf	Kadavar	m
362f8cdd1065b0f33e73208eb358991d	Kambrium	y
820de5995512273916b117944d6da15a	Kataklysm	y
d39d7a2bb6d430fd238a6aedc7f0cee2	Knife	m
6d57b25c282247075f5e03cde27814df	Knockdown Brutality	y
bbb668ff900efa57d936e726a09e4fe8	Korpiklaani	y
2501f7ba78cc0fd07efb7c17666ff12e	Korpse	y
76700087e932c3272e05694610d604ba	Kosmokrator	m
9b1088b616414d0dc515ab1f2b4922f1	Kreator	y
dfdef9b5190f331de20fe029babf032e	Lacrimas Profundere	m
4cfab0d66614c6bb6d399837656c590e	Legion of the Damned	y
5b22d1d5846a2b6b6d0cf342e912d124	Light to the blind	m
710ba5ed112368e3ce50e2c84b17210c	Lik	y
4261335bcdc95bd89fd530ba35afbf4c	Liver Values	m
2cfe35095995e8dd15ab7b867e178c15	Lonewolf	y
2cf65e28c586eeb98daaecf6eb573e7a	Lordi	m
3cdb47307aeb005121b09c41c8d8bee6	Los Skeleteros	y
53407737e93f53afdfc588788b8288e8	Lyra's Legacy	n
006fc2724417174310cf06d2672e34d2	M????t	y
7db066b46f48d010fdb8c87337cdeda4	Madball	y
a3f5542dc915b94a5e10dab658bb0959	Manegarm	y
2ac79000a90b015badf6747312c0ccad	Mantar	y
eb2c788da4f36fba18b85ae75aff0344	Marduk	y
626dceb92e4249628c1e76a2c955cd24	Meatknife	y
8fda25275801e4a40df6c73078baf753	Mecalimb	m
3a2a7f86ca87268be9b9e0557b013565	Membaris	m
ac03fad3be179a237521ec4ef2620fb0	Metal Inquisitor	n
8b0ee5a501cef4a5699fd3b2d4549e8f	Metallica	y
7e2b83d69e6c93adf203e13bc7d6f444	Milking the Goatmachine	y
0fbddeb130361265f1ba6f86b00f0968	Mindflair	y
3f15c445cb553524b235b01ab75fe9a6	Ministry	y
656d1497f7e25fe0559c6be81a4bccae	Misery Index	y
f60ab90d94b9cafe6b32f6a93ee8fcda	Mizery	m
8775f64336ee5e9a8114fbe3a5a628c5	M??L	y
e872b77ff7ac24acc5fa373ebe9bb492	Molotov	y
f0e1f32b93f622ea3ddbf6b55b439812	Mono Inc.	m
53a0aafa942245f18098ccd58b4121aa	Moontowers	n
0780d2d1dbd538fec3cdd8699b08ea02	Morasth	y
4a45ac6d83b85125b4163a40364e7b2c	More Than A Thousand	m
58db028cf01dd425e5af6c7d511291c1	Moronic	y
2252d763a2a4ac815b122a0176e3468f	Mosaic	y
11d396b078f0ae37570c8ef0f45937ad	Mot??rblast	y
585b13106ecfd7ede796242aeaed4ea8	Motorowl	y
6c1fcd3c91bc400e5c16f467d75dced3	Mr. Irish Bastard	y
a7f9797e4cd716e1516f9d4845b0e1e2	Municipal Waste	m
7d878673694ff2498fbea0e5ba27e0ea	Nailed to Obscurity	y
0844ad55f17011abed4a5208a3a05b74	Napalm Death	y
6738f9acd4740d945178c649d6981734	Nasty	m
fd85bfffd5a0667738f6110281b25db8	Necrotted	y
33f03dd57f667d41ac77c6baec352a81	need2destroy	y
3509af6be9fe5defc1500f5c77e38563	Nekrovault	y
0640cfbf1d269b69c535ea4e288dfd96	Nepumuc	m
a716390764a4896d99837e99f9e009c9	Nervosa	y
e74a88c71835c14d92d583a1ed87cc6c	Nifelheim	y
3d6ff25ab61ad55180a6aee9b64515bf	Nile	y
36648510adbf2a3b2028197a60b5dada	NIOR	y
eb3bfb5a3ccdd4483aabc307ae236066	No Brainer	y
1ebd63d759e9ff532d5ce63ecb818731	Nocte Obducta	m
1c06fc6740d924cab33dce73643d84b9	Nocturnal Graves	y
4a2a0d0c29a49d9126dcb19230aa1994	No Return	y
059792b70fc0686fb296e7fcae0bda50	Obscenity	m
7dfe9aa0ca5bb31382879ccd144cc3ae	Of Colours	y
a650d82df8ca65bb69a45242ab66b399	Omnium Gatherum	y
3dda886448fe98771c001b56a4da9893	Omophagia	y
d73310b95e8b4dece44e2a55dd1274e6	Orbit Culture	y
fb28e62c0e801a787d55d97615e89771	Orcus Patera	y
652208d2aa8cdd769632dbaeb7a16358	Orden Ogan	y
660813131789b822f0c75c667e23fc85	Overkill	m
b5f7b25b0154c34540eea8965f90984d	Pain City	y
a7a9c1b4e7f10bd1fdf77aff255154f7	Papa Roach	m
e64d38b05d197d60009a43588b2e4583	Paradise Lost	m
88711444ece8fe638ae0fb11c64e2df3	Party Cannon	y
278c094627c0dd891d75ea7a3d0d021e	Paxtilence	y
0a56095b73dcbd2a76bb9d4831881cb3	Phantom Winter	n
ff578d3db4dc3311b3098c8365d54e6b	Pighead	y
80fcd08f6e887f6cfbedd2156841ab2b	P.O. Box	y
db38e12f9903b156f9dc91fce2ef3919	Pokerface	m
90d127641ffe2a600891cd2e3992685b	Poltergeist	m
2e7a848dc99bd27acb36636124855faf	Porn the Gore	y
79566192cda6b33a9ff59889eede2d66	Power Trip	y
3964d4f40b6166aa9d370855bd20f662	Prediction	y
4548a3b9c1e31cf001041dc0d166365b	Pripjat	y
450948d9f14e07ba5e3015c2d726b452	Promethee	y
c4678a2e0eef323aeb196670f2bc8a6e	Prostitute Desfigurement	y
c1923ca7992dc6e79d28331abbb64e72	Psycroptic	y
5842a0c2470fe12ee3acfeec16c79c57	Public Grave	y
96682d9c9f1bed695dbf9176d3ee234c	Purify	y
7f29efc2495ce308a8f4aa7bfc11d701	Randy Hansen	y
12e93f5fab5f7d16ef37711ef264d282	Raw Ensemble	y
4094ffd492ba473a2a7bea1b19b1662d	Reactory	y
02d44fbbe1bfacd6eaa9b20299b1cb78	Rectal Smegma	y
9ab8f911c74597493400602dc4d2b412	Refuge	y
11f8d9ec8f6803ea61733840f13bc246	Relics of Humanity	y
54f0b93fa83225e4a712b70c68c0ab6f	Revelation Steel	m
1cdd53cece78d6e8dffcf664fa3d1be2	Revel in Flesh	y
1e88302efcfc873691f0c31be4e2a388	Rezet	y
2af9e4497582a6faa68a42ac2d512735	Rings of Saturn	y
13caf3d14133dfb51067264d857eaf70	Risk it	y
1e14d6b40d8e81d8d856ba66225dcbf3	Riverroth	m
5b20ea1312a1a21beaa8b86fe3a07140	Rivers of Nihil	y
fa03eb688ad8aa1db593d33dabd89bad	Root	y
7a4fafa7badd04d5d3114ab67b0caf9d	Saltatio Mortis	n
4cabe475dd501f3fd4da7273b5890c33	Samael	y
f8e7112b86fcd9210dfaf32c00d6d375	Sanguine	n
91c9ed0262dea7446a4f3a3e1cdd0698	Satan's Fall	n
79ce9bd96a3184b1ee7c700aa2927e67	Schizophrenia	y
218f2bdae8ad3bb60482b201e280ffdc	Scordatura	y
4927f3218b038c780eb795766dfd04ee	Scornebeke	y
0a97b893b92a7df612eadfe97589f242	Scrvmp	y
31d8a0a978fad885b57a685b1a0229df	Seii Taishogun	y
7ef36a3325a61d4f1cff91acbe77c7e3	Sensles	m
5b709b96ee02a30be5eee558e3058245	Sepultura	y
19baf8a6a25030ced87cd0ce733365a9	Serrabulho	y
4ee21b1371ba008a26b313c7622256f8	Shambala	m
91b18e22d4963b216af00e1dd43b5d05	Shoot the Girl first	n
6bd19bad2b0168d4481b19f9c25b4a9f	Shores of Null	y
53369c74c3cacdc38bdcdeda9284fe3c	Siberian Meat Grinder	y
6bafe8cf106c32d485c469d36c056989	Sick of it all	y
66599a31754b5ac2a202c46c2b577c8e	Six Feet Under	m
4453eb658c6a304675bd52ca75fbae6d	Skeleton Pit	y
5e4317ada306a255748447aef73fff68	Skeletonwitch	y
65976b6494d411d609160a2dfd98f903	Skindred	y
360c000b499120147c8472998859a9fe	Skinned Alive	y
e62a773154e1179b0cc8c5592207cb10	Skull Fist	n
4bb93d90453dd63cc1957a033f7855c7	Slaughterra	y
121189969c46f49b8249633c2d5a7bfa	Slayer	y
f29d276fd930f1ad7687ed7e22929b64	Sleepers' Guilt	y
249229ca88aa4a8815315bb085cf4d61	Slipknot	y
c05d504b806ad065c9b548c0cb1334cd	Sober Truth	m
b96a3cb81197e8308c87f6296174fe3e	Sodom	y
8edf4531385941dfc85e3f3d3e32d24f	Soilwork	y
90d523ebbf276f516090656ebfccdc9f	Solstafir	n
94ca28ea8d99549c2280bcc93f98c853	Soulburn	y
076365679712e4206301117486c3d0ec	Soulfly	y
abd7ab19ff758cf4c1a2667e5bbac444	Spasm	y
0af74c036db52f48ad6cbfef6fee2999	Stam1na	y
095849fbdc267416abc6ddb48be311d7	Stillbirth	y
72778afd2696801f5f3a1f35d0e4e357	Still Patient?	m
5c0adc906f34f9404d65a47eea76dac0	Stonefall	y
fdcf3cdc04f367257c92382e032b6293	Storm	y
8bc31f7cc79c177ab7286dda04e2d1e5	Street Dogs	y
88dd124c0720845cba559677f3afa15d	Sucking Leech	y
2df8905eae6823023de6604dc5346c29	Suicidal Angels	y
7e0d5240ec5d34a30b6f24909e5edcb4	Suicidal Tendencies	y
f4f870098db58eeae93742dd2bcaf2b2	Sulphur Aeon	y
d433b7c1ce696b94a8d8f72de6cfbeaa	Sun of the Sleepless	y
28bb59d835e87f3fd813a58074ca0e11	Supreme Carnage	y
aa0d528ba11ea1485d466dfe1ea40819	Surface	y
bbc155fb2b111bf61c4f5ff892915e6b	Switch	y
f953fa7b33e7b6503f4380895bbe41c8	Take Offense	m
cafe9e68e8f90b3e1328da8858695b31	Tankard	m
ad62209fb63910acf40280cea3647ec5	Task Force Beer	y
0a267617c0b5b4d53e43a7d4e4c522ad	Teethgrinder	y
058fcf8b126253956deb3ce672d107a7	Terror	y
b14814d0ee12ffadc8f09ab9c604a9d0	Testament	y
5447110e1e461c8c22890580c796277a	The black Dahlia Murder	y
9e84832a15f2698f67079a3224c2b6fb	The Creatures from the Tomb	y
4a7d9e528dada8409e88865225fb27c4	The Feelgood McLouds	y
d3e98095eeccaa253050d67210ef02bb	The Idiots	y
c3490492512b7fe65cdb0c7305044675	The Jailbreakers	y
e61e30572fd58669ae9ea410774e0eb6	The Monolith Project	y
990813672e87b667add44c712bb28d3d	The Ominous Circle	y
8143ee8032c71f6f3f872fc5bb2a4fed	The Phobos Ensemble	m
485065ad2259054abf342d7ae3fe27e6	The Privateer	m
278606b1ac0ae7ef86e86342d1f259c3	The Prophecy 23	y
a538bfe6fe150a92a72d78f89733dbd0	The Spirit	m
c127f32dc042184d12b8c1433a77e8c4	The Vintage Caravan	m
e4b3296f8a9e2a378eb3eb9576b91a37	Thornafire	y
09d8e20a5368ce1e5c421a04cb566434	Thrudvangar	y
4366d01be1b2ddef162fc0ebb6933508	Thunderstorm	m
46174766ce49edbbbc40e271c87b5a83	Thy Antichrist	y
4fa857a989df4e1deea676a43dceea07	Too many Assholes	y
36cbc41c1c121f2c68f5776a118ea027	Tornado	m
da867941c8bacf9be8e59bc13d765f92	Traitors	y
6ee2e6d391fa98d7990b502e72c7ec58	Trancemission	m
a4977b96c7e5084fcce21a0d07b045f8	Tribulation	y
1da77fa5b97c17be83cc3d0693c405cf	Twitching Tongues	m
e0f39406f0e15487dd9d3997b2f5ca61	??bergang	y
399033f75fcf47d6736c9c5209222ab8	Undertow	y
6f195d8f9fe09d45d2e680f7d7157541	Une Misere	y
2113f739f81774557041db616ee851e6	Unleashed	m
32814ff4ca9a26b8d430a8c0bc8dc63e	Ur	y
e29ef4beb480eab906ffa7c05aeec23d	Vader	y
2447873ddeeecaa165263091c0cbb22f	Vargsheim	y
86482a1e94052aa18cd803a51104cdb9	Vektor	y
fcd1c1b547d03e760d1defa4d2b98783	Victorius	n
6369ba49db4cf35b35a7c47e3d4a4fd0	Visdom	m
935b48a84528c4280ec208ce529deea0	Visions of Disfigurement	y
52b133bfecec2fba79ecf451de3cf3bb	V??lkerball	y
559ccea48c3460ebc349587d35e808dd	Vomitory	y
8e11b2f987a99ed900a44aa1aa8bd3d0	Vortex	n
59f06d56c38ac98effb4c6da117b0305	Walls of Jericho	y
804803e43d2c779d00004a6e87f28e30	Warbringer	y
f042da2a954a1521114551a6f9e22c75	Warfield	y
b1d465aaf3ccf8701684211b1623adf2	Warkings	m
4f840b1febbbcdb12b9517cd0a91e8f4	When Plagues Collide	y
c2855b6617a1b08fed3824564e15a653	Whitechapel	m
405c7f920b019235f244315a564a8aed	Who killed Janis	m
8e62fc75d9d0977d0be4771df05b3c2f	Wintersun	y
cd9483c1733b17f57d11a77c9404893c	Wisdom in Chains	m
3656edf3a40a25ccd00d414c9ecbb635	Witchfucker	y
6d89517dbd1a634b097f81f5bdbb07a2	Witchhunter	m
db46d9a37b31baa64cb51604a2e4939a	Within Destruction	y
5af874093e5efcbaeb4377b84c5f2ec5	Wizard	m
8a6f1a01e4b0d9e272126a8646a72088	Wolfheart	y
5037c1968f3b239541c546d32dec39eb	World of Tomorrow	m
3e52c77d795b7055eeff0c44687724a1	Xaon	y
5952dff7a6b1b3c94238ad3c6a42b904	Zebrahead	m
deaccc41a952e269107cc9a507dfa131	Zodiac	y
bb4cc149e8027369e71eb1bb36cd98e0	Zombi	m
754230e2c158107a2e93193c829e9e59	Crisix	y
a29c1c4f0a97173007be3b737e8febcc	Redgrin	y
4fab532a185610bb854e0946f4def6a4	Torment of Souls	y
e25ee917084bdbdc8506b56abef0f351	Skelethal	y
e6fd7b62a39c109109d33fcd3b5e129d	Keitzer	y
da29e297c23e7868f1d50ec5a6a4359b	Blodt??ke	y
96048e254d2e02ba26f53edd271d3f88	Souldevourer	y
c2275e8ac71d308946a63958bc7603a1	Fabulous Desaster	y
3bcbddf6c114327fc72ea06bcb02f9ef	Satan Worship	y
dde3e0b0cc344a7b072bbab8c429f4ff	The Laws Kill Destroy (F??bio Jhasko's Sarc??fago tribute)	y
b785a5ffad5e7e36ccac25c51d5d8908	Mortal Peril	y
63c0a328ae2bee49789212822f79b83f	Infected Inzestor	y
83d15841023cff02eafedb1c87df9b11	Birdflesh	m
f03bde11d261f185cbacfa32c1c6538c	Master	y
f6540bc63be4c0cb21811353c0d24f69	Misanthropia	y
e4f0ad5ef0ac3037084d8a5e3ca1cabc	Pestilence	m
ea16d031090828264793e860a00cc995	Severe Torture	y
5eed658c4b7b68a0ecc49205b68d54e7	Undying Lust for Cadaverous Molestation (UxLxCxM)	y
96e3cdb363fe6df2723be5b994ad117a	Lecks inc.	y
4ad6c928711328d1cf0167bc87079a14	Hate	y
a0fb30950d2a150c1d2624716f216316	Belphegor	y
c8d551145807972d194691247e7102a2	I am Morbid	y
45b568ce63ea724c415677711b4328a7	Baest	y
145bd9cf987b6f96fa6f3b3b326303c9	Der rote Milan	y
c238980432ab6442df9b2c6698c43e47	??era	y
39a25b9c88ce401ca54fd7479d1c8b73	Jesajah	y
8cadf0ad04644ce2947bf3aa2817816e	Balberskult	y
85fac49d29a31f1f9a8a18d6b04b9fc9	Hellburst	y
b81ee269be538a500ed057b3222c86a2	Crypts	y
5518086aebc9159ba7424be0073ce5c9	Wound	y
60f28c7011b5e32d220cbaa0e563291b	Horns Of Domination	y
6eaeee13a99072e69bab1f707b79c56a	THRON	y
2c4e2c9948ddac6145e529c2ae7296da	Venefixion	y
c9af1c425ca093648e919c2e471df3bd	Asagraum	y
0291e38d9a3d398052be0ca52a7b1592	Possession	y
8852173e80d762d62f0bcb379d82ebdb	Grave Miasma	m
000f49c98c428aff4734497823d04f45	Sacramentum???	m
dea293bdffcfb292b244b6fe92d246dc	Impaled Nazarene	m
cf71a88972b5e06d8913cf53c916e6e4	Bloodland	y
ac62ad2816456aa712809bf01327add1	LAWM??NNER	n
302ebe0389198972c223f4b72894780a	Stagewar	m
470f3f69a2327481d26309dc65656f44	The Fog	y
e254616b4a5bd5aaa54f90a3985ed184	Goath	y
3c5c578b7cf5cc0d23c1730d1d51436a	Velvet Viper	n
eaeaed2d9f3137518a5c8c7e6733214f	Elmsfire	m
8ccd65d7f0f028405867991ae3eaeb56	Pois??ned Speed	y
781acc7e58c9a746d58f6e65ab1e90c4	Harakiri For The Sky	y
e5a674a93987de4a52230105907fffe9	Nachtblut	y
a2459c5c8a50215716247769c3dea40b	Mister Misery	m
e285e4ecb358b92237298f67526beff7	Pyogenesis	n
d832b654664d104f0fbb9b6674a09a11	Sch??ngeist	y
2aeb128c6d3eb7e79acb393b50e1cf7b	Enter Tragedy	y
213c449bd4bcfcdb6bffecf55b2c30b4	Erdling	y
4ea353ae22a1c0d26327638f600aeac8	Stahlmann	y
66244bb43939f81c100f03922cdc3439	Sabaton	y
\.


--
-- Data for Name: bands_countries; Type: TABLE DATA; Schema: music; Owner: postgres
--

COPY music.bands_countries (id_band, id_country) FROM stdin;
8b427a493fc39574fc801404bc032a2f	6b718641741f992e68ec3712718561b8
721c28f4c74928cc9e0bb3fef345e408	6c1674d14bf5f95742f572cddb0641a7
0a7ba3f35a9750ff956dca1d548dad12	d8b00929dec65d422303256336ada04f
54b72f3169fea84731d3bcba785eac49	d8b00929dec65d422303256336ada04f
d05a0e65818a69cc689b38c0c0007834	d8b00929dec65d422303256336ada04f
dcabc7299e2b9ed5b05c33273e5fdd19	d8b00929dec65d422303256336ada04f
5ce10014f645da4156ddd2cd0965986e	f75d91cdd36b85cc4a8dfeca4f24fa14
a332f1280622f9628fccd1b7aac7370a	d8b00929dec65d422303256336ada04f
249789ae53c239814de8e606ff717ec9	1007e1b7f894dfbf72a0eaa80f3bc57e
b1bdad87bd3c4ac2c22473846d301a9e	d8b00929dec65d422303256336ada04f
fe5b73c2c2cd2d9278c3835c791289b6	d8b00929dec65d422303256336ada04f
942c9f2520684c22eb6216a92b711f9e	c8f4261f9f46e6465709e17ebea7a92b
7cd7921da2e6aab79c441a0c2ffc969b	6f781c6559a0c605da918096bdb69edf
948098e746bdf1c1045c12f042ea98c2	ea71b362e3ea9969db085abfccdeb10d
59d153c1c2408b702189623231b7898a	907eba32d950bfab68227fd7ea22999b
06efe152a554665e02b8dc4f620bf3f1	f75d91cdd36b85cc4a8dfeca4f24fa14
14ab730fe0172d780da6d9e5d432c129	d8b00929dec65d422303256336ada04f
449b4d758aa7151bc1bbb24c3ffb40bb	33cac763789c407f405b2cf0dce7df89
5df92b70e2855656e9b3ffdf313d7379	c8f4261f9f46e6465709e17ebea7a92b
3e75cd2f2f6733ea4901458a7ce4236d	fa79c3005daec47ecff84a116a0927a1
108c58fc39b79afc55fac7d9edf4aa2a	c8f4261f9f46e6465709e17ebea7a92b
28bc31b338dbd482802b77ed1fd82a50	d8b00929dec65d422303256336ada04f
49c4097bae6c6ea96f552e38cfb6c2d1	424214945ba5615eca039bfe5d731c09
e3f0bf612190af6c3fad41214115e004	76423d8352c9e8fc8d7d65f62c55eae9
fb47f889f2c7c4fee1553d0f817b8aaa	a67d4cbdd1b59e0ffccc6bafc83eb033
264721f3fc2aee2d28dadcdff432dbc1	d8b00929dec65d422303256336ada04f
9a322166803a48932356586f05ef83c7	c8f4261f9f46e6465709e17ebea7a92b
75ab0270163731ee05f35640d56ef473	d5b9290a0b67727d4ba1ca6059dc31a6
9d3ac6904ce73645c6234803cd7e47ca	d8b00929dec65d422303256336ada04f
d1fb4e47d8421364f49199ee395ad1d3	4442e4af0916f53a07fb8ca9a49b98ed
44012166c6633196dc30563db3ffd017	d8b00929dec65d422303256336ada04f
905a40c3533830252a909603c6fa1e6a	907eba32d950bfab68227fd7ea22999b
aed85c73079b54830cd50a75c0958a90	d8b00929dec65d422303256336ada04f
da2110633f62b16a571c40318e4e4c1c	d8b00929dec65d422303256336ada04f
529a1d385b4a8ca97ea7369477c7b6a7	6f781c6559a0c605da918096bdb69edf
d3ed8223151e14b936436c336a4c7278	94880bda83bda77c5692876700711f15
ce2caf05154395724e4436f042b8fa53	d8b00929dec65d422303256336ada04f
be20385e18333edb329d4574f364a1f0	94880bda83bda77c5692876700711f15
ee69e7d19f11ca58843ec2e9e77ddb38	76423d8352c9e8fc8d7d65f62c55eae9
925bd435e2718d623768dbf1bc1cfb60	0309a6c666a7a803fdb9db95de71cf01
ad01952b3c254c8ebefaf6f73ae62f7d	d8b00929dec65d422303256336ada04f
7c7ab6fbcb47bd5df1e167ca28220ee9	0309a6c666a7a803fdb9db95de71cf01
e8afde257f8a2cbbd39d866ddfc06103	9891739094756d2605946c867b32ad28
8f1f10cb698cb995fd69a671af6ecd58	f75d91cdd36b85cc4a8dfeca4f24fa14
bbddc022ee323e0a2b2d8c67e5cd321f	d8b00929dec65d422303256336ada04f
74b3b7be6ed71b946a151d164ad8ede5	76423d8352c9e8fc8d7d65f62c55eae9
d9ab6b54c3bd5b212e8dc3a14e7699ef	d8b00929dec65d422303256336ada04f
679eaa47efb2f814f2642966ee6bdfe1	d8b00929dec65d422303256336ada04f
e1db3add02ca4c1af33edc5a970a3bdc	d8b00929dec65d422303256336ada04f
1c6987adbe5ab3e4364685e8caed0f59	c8f4261f9f46e6465709e17ebea7a92b
cf4ee20655dd3f8f0a553c73ffe3f72a	d8b00929dec65d422303256336ada04f
348bcdb386eb9cb478b55a7574622b7c	a67d4cbdd1b59e0ffccc6bafc83eb033
b3ffff8517114caf70b9e70734dbaf6f	6f781c6559a0c605da918096bdb69edf
a4cbfb212102da21b82d94be555ac3ec	d5b9290a0b67727d4ba1ca6059dc31a6
10d91715ea91101cfe0767c812da8151	d8b00929dec65d422303256336ada04f
1209f43dbecaba22f3514bf40135f991	d8b00929dec65d422303256336ada04f
dcff9a127428ffb03fc02fdf6cc39575	d8b00929dec65d422303256336ada04f
6c00bb1a64f660600a6c1545377f92dc	d5b9290a0b67727d4ba1ca6059dc31a6
55159d04cc4faebd64689d3b74a94009	76423d8352c9e8fc8d7d65f62c55eae9
b6da055500e3d92698575a3cfc74906c	a67d4cbdd1b59e0ffccc6bafc83eb033
1e9413d4cc9af0ad12a6707776573ba0	d8b00929dec65d422303256336ada04f
b01fbaf98cfbc1b72e8bca0b2e48769c	d8b00929dec65d422303256336ada04f
4b98a8c164586e11779a0ef9421ad0ee	d8b00929dec65d422303256336ada04f
897edb97d775897f69fa168a88b01c19	445d337b5cd5de476f99333df6b0c2a7
eeaeec364c925e0c821660c7a953546e	76423d8352c9e8fc8d7d65f62c55eae9
7533f96ec01fd81438833f71539c7d4e	c8f4261f9f46e6465709e17ebea7a92b
11635778f116ce6922f6068638a39028	f75d91cdd36b85cc4a8dfeca4f24fa14
d449a9b2eed8b0556dc7be9cda36b67b	76423d8352c9e8fc8d7d65f62c55eae9
7eaf9a47aa47f3c65595ae107feab05d	d8b00929dec65d422303256336ada04f
7463543d784aa59ca86359a50ef58c8e	76423d8352c9e8fc8d7d65f62c55eae9
c4f0f5cedeffc6265ec3220ab594d56b	c8f4261f9f46e6465709e17ebea7a92b
63bd9a49dd18fbc89c2ec1e1b689ddda	f75d91cdd36b85cc4a8dfeca4f24fa14
63ae1791fc0523f47bea9485ffec8b8c	a67d4cbdd1b59e0ffccc6bafc83eb033
c4c7cb77b45a448aa3ca63082671ad97	3ad08396dc5afa78f34f548eea3c1d64
5435326cf392e2cd8ad7768150cd5df6	6c1674d14bf5f95742f572cddb0641a7
828d51c39c87aad9b1407d409fa58e36	d8b00929dec65d422303256336ada04f
d2ff1e521585a91a94fb22752dd0ab45	d8b00929dec65d422303256336ada04f
77f2b3ea9e4bd785f5ff322bae51ba07	6f781c6559a0c605da918096bdb69edf
6f199e29c5782bd05a4fef98e7e41419	3ad08396dc5afa78f34f548eea3c1d64
b0ce1e93de9839d07dab8d268ca23728	d8b00929dec65d422303256336ada04f
6830afd7158930ca7d1959ce778eb681	d5b9290a0b67727d4ba1ca6059dc31a6
a61b878c2b563f289de2109fa0f42144	76423d8352c9e8fc8d7d65f62c55eae9
e67e51d5f41cfc9162ef7fd977d1f9f5	f75d91cdd36b85cc4a8dfeca4f24fa14
3d2ff8abd980d730b2f4fd0abae52f60	f75d91cdd36b85cc4a8dfeca4f24fa14
ffa7450fd138573d8ae665134bccd02c	6f781c6559a0c605da918096bdb69edf
faabbecd319372311ed0781d17b641d1	445d337b5cd5de476f99333df6b0c2a7
51fa80e44b7555c4130bd06c53f4835c	76423d8352c9e8fc8d7d65f62c55eae9
9f19396638dd8111f2cee938fdf4e455	d8b00929dec65d422303256336ada04f
fdcbfded0aaf369d936a70324b39c978	d8b00929dec65d422303256336ada04f
47b23e889175dde5d6057db61cb52847	f75d91cdd36b85cc4a8dfeca4f24fa14
1056b63fdc3c5015cc4591aa9989c14f	d8b00929dec65d422303256336ada04f
b5d9c5289fe97968a5634b3e138bf9e2	445d337b5cd5de476f99333df6b0c2a7
2876f7ecdae220b3c0dcb91ff13d0590	d8b00929dec65d422303256336ada04f
1734b04cf734cb291d97c135d74b4b87	d8b00929dec65d422303256336ada04f
7d6b45c02283175f490558068d1fc81b	0309a6c666a7a803fdb9db95de71cf01
8d7a18d54e82fcfb7a11566ce94b9109	d8b00929dec65d422303256336ada04f
dddb04bc0d058486d0ef0212c6ea0682	0309a6c666a7a803fdb9db95de71cf01
0e2ea6aa669710389cf4d6e2ddf408c4	d8b00929dec65d422303256336ada04f
63ad3072dc5472bb44c2c42ede26d90f	d8b00929dec65d422303256336ada04f
2aae4f711c09481c8353003202e05359	d8b00929dec65d422303256336ada04f
28f843fa3a493a3720c4c45942ad970e	d8b00929dec65d422303256336ada04f
9bc2ca9505a273b06aa0b285061cd1de	6b718641741f992e68ec3712718561b8
9138c2cc0326412f2515623f4c850eb3	d8b00929dec65d422303256336ada04f
44b7bda13ac1febe84d8607ca8bbf439	f75d91cdd36b85cc4a8dfeca4f24fa14
d857ab11d383a7e4d4239a54cbf2a63d	d8b00929dec65d422303256336ada04f
c74b5aa120021cbe18dcddd70d8622da	9891739094756d2605946c867b32ad28
3af7c6d148d216f13f66669acb8d5c59	d8b00929dec65d422303256336ada04f
522b6c44eb0aedf4970f2990a2f2a812	94880bda83bda77c5692876700711f15
f4219e8fec02ce146754a5be8a85f246	d8b00929dec65d422303256336ada04f
c5f022ef2f3211dc1e3b8062ffe764f0	3ad08396dc5afa78f34f548eea3c1d64
0ab20b5ad4d15b445ed94fa4eebb18d8	d8b00929dec65d422303256336ada04f
7fc454efb6df96e012e0f937723d24aa	d8b00929dec65d422303256336ada04f
8edfa58b1aedb58629b80e5be2b2bd92	d8b00929dec65d422303256336ada04f
8589a6a4d8908d7e8813e9a1c5693d70	f75d91cdd36b85cc4a8dfeca4f24fa14
947ce14614263eab49f780d68555aef8	c8f4261f9f46e6465709e17ebea7a92b
7c83727aa466b3b1b9d6556369714fcf	33cac763789c407f405b2cf0dce7df89
71e32909a1bec1edfc09aec09ca2ac17	06630c890abadde9228ea818ce52b621
3d01ff8c75214314c4ca768c30e6807b	d8b00929dec65d422303256336ada04f
7771012413f955f819866e517b275cb4	0309a6c666a7a803fdb9db95de71cf01
36f969b6aeff175204078b0533eae1a0	4442e4af0916f53a07fb8ca9a49b98ed
1bc1f7348d79a353ea4f594de9dd1392	f75d91cdd36b85cc4a8dfeca4f24fa14
2082a7d613f976e7b182a3fe80a28958	d5b9290a0b67727d4ba1ca6059dc31a6
d9bc1db8c13da3a131d853237e1f05b2	d8b00929dec65d422303256336ada04f
9cf73d0300eea453f17c6faaeb871c55	d8b00929dec65d422303256336ada04f
4dddd8579760abb62aa4b1910725e73c	a67d4cbdd1b59e0ffccc6bafc83eb033
d6de9c99f5cfa46352b2bc0be5c98c41	d8b00929dec65d422303256336ada04f
5194c60496c6f02e8b169de9a0aa542c	d8b00929dec65d422303256336ada04f
8654991720656374d632a5bb0c20ff11	d8b00929dec65d422303256336ada04f
6a0e9ce4e2da4f2cbcd1292fddaa0ac6	f75d91cdd36b85cc4a8dfeca4f24fa14
fe228019addf1d561d0123caae8d1e52	d8b00929dec65d422303256336ada04f
1104831a0d0fe7d2a6a4198c781e0e0d	d8b00929dec65d422303256336ada04f
889aaf9cd0894206af758577cf5cf071	76423d8352c9e8fc8d7d65f62c55eae9
410d913416c022077c5c1709bf104d3c	d8b00929dec65d422303256336ada04f
c5dc33e23743fb951b3fe7f1f477b794	d5b9290a0b67727d4ba1ca6059dc31a6
97ee29f216391d19f8769f79a1218a71	d8b00929dec65d422303256336ada04f
b885447285ece8226facd896c04cdba2	fa79c3005daec47ecff84a116a0927a1
3614c45db20ee41e068c2ab7969eb3b5	9891739094756d2605946c867b32ad28
c4ddbffb73c1c34d20bd5b3f425ce4b1	1007e1b7f894dfbf72a0eaa80f3bc57e
f07c3eef5b7758026d45a12c7e2f6134	d8b00929dec65d422303256336ada04f
9d969d25c9f506c5518bb090ad5f8266	6b718641741f992e68ec3712718561b8
0b6e98d660e2901c33333347da37ad36	3ad08396dc5afa78f34f548eea3c1d64
6d3b28f48c848a21209a84452d66c0c4	d8b00929dec65d422303256336ada04f
8c69497eba819ee79a964a0d790368fb	d8b00929dec65d422303256336ada04f
1197a69404ee9475146f3d631de12bde	d8b00929dec65d422303256336ada04f
d730e65d54d6c0479561d25724afd813	c8f4261f9f46e6465709e17ebea7a92b
457f098eeb8e1518008449e9b1cb580d	1007e1b7f894dfbf72a0eaa80f3bc57e
ac94d15f46f10707a39c4bc513cd9f98	f75d91cdd36b85cc4a8dfeca4f24fa14
37f02eba79e0a3d29dfd6a4cf2f4d019	a67d4cbdd1b59e0ffccc6bafc83eb033
39e83bc14e95fcbc05848fc33c30821f	51802d8bb965d0e5be697f07d16922e8
f0c051b57055b052a3b7da1608f3039e	d8b00929dec65d422303256336ada04f
e08383c479d96a8a762e23a99fd8bf84	c8f4261f9f46e6465709e17ebea7a92b
ff5b48d38ce7d0c47c57555d4783a118	d8b00929dec65d422303256336ada04f
8945663993a728ab19a3853e5b820a42	6c1674d14bf5f95742f572cddb0641a7
28a95ef0eabe44a27f49bbaecaa8a847	f75d91cdd36b85cc4a8dfeca4f24fa14
0cdf051c93865faa15cbc5cd3d2b69fb	f75d91cdd36b85cc4a8dfeca4f24fa14
ade72e999b4e78925b18cf48d1faafa4	d8b00929dec65d422303256336ada04f
4b503a03f3f1aec6e5b4d53dd8148498	6542f875eaa09a5c550e5f3986400ad9
887d6449e3544dca547a2ddba8f2d894	d8b00929dec65d422303256336ada04f
2672777b38bc4ce58c49cf4c82813a42	d8b00929dec65d422303256336ada04f
832dd1d8efbdb257c2c7d3e505142f48	d8b00929dec65d422303256336ada04f
f37ab058561fb6d233b9c2a0b080d4d1	d8b00929dec65d422303256336ada04f
3be3e956aeb5dc3b16285463e02af25b	d8b00929dec65d422303256336ada04f
42563d0088d6ac1a47648fc7621e77c6	d8b00929dec65d422303256336ada04f
7df8865bbec157552b8a579e0ed9bfe3	f75d91cdd36b85cc4a8dfeca4f24fa14
c883319a1db14bc28eff8088c5eba10e	d8b00929dec65d422303256336ada04f
6b7cf117ecf0fea745c4c375c1480cb5	d8b00929dec65d422303256336ada04f
187ebdf7947f4b61e0725c93227676a4	1007e1b7f894dfbf72a0eaa80f3bc57e
4276250c9b1b839b9508825303c5c5ae	d8b00929dec65d422303256336ada04f
7462f03404f29ea618bcc9d52de8e647	d8b00929dec65d422303256336ada04f
5efb7d24387b25d8325839be958d9adf	d8b00929dec65d422303256336ada04f
9db9bc745a7568b51b3a968d215ddad6	c8f4261f9f46e6465709e17ebea7a92b
cddf835bea180bd14234a825be7a7a82	a67d4cbdd1b59e0ffccc6bafc83eb033
fdc90583bd7a58b91384dea3d1659cde	0309a6c666a7a803fdb9db95de71cf01
401357e57c765967393ba391a338e89b	c8f4261f9f46e6465709e17ebea7a92b
e64b94f14765cee7e05b4bec8f5fee31	a67d4cbdd1b59e0ffccc6bafc83eb033
d0a1fd0467dc892f0dc27711637c864e	a67d4cbdd1b59e0ffccc6bafc83eb033
e271e871e304f59e62a263ffe574ea2d	d8b00929dec65d422303256336ada04f
a8d9eeed285f1d47836a5546a280a256	d8b00929dec65d422303256336ada04f
abbf8e3e3c3e78be8bd886484c1283c1	d8b00929dec65d422303256336ada04f
87f44124fb8d24f4c832138baede45c7	c8f4261f9f46e6465709e17ebea7a92b
ed24ff8971b1fa43a1efbb386618ce35	c8f4261f9f46e6465709e17ebea7a92b
33b6f1b596a60fa87baef3d2c05b7c04	6f781c6559a0c605da918096bdb69edf
426fdc79046e281c5322161f011ce68c	907eba32d950bfab68227fd7ea22999b
988d10abb9f42e7053450af19ad64c7f	d8b00929dec65d422303256336ada04f
dd18fa7a5052f2bce8ff7cb4a30903ea	51802d8bb965d0e5be697f07d16922e8
b89e91ccf14bfd7f485dd7be7d789b0a	f75d91cdd36b85cc4a8dfeca4f24fa14
87ded0ea2f4029da0a0022000d59232b	4442e4af0916f53a07fb8ca9a49b98ed
2a024edafb06c7882e2e1f7b57f2f951	d8b00929dec65d422303256336ada04f
2fa2f1801dd37d6eb9fe4e34a782e397	d8b00929dec65d422303256336ada04f
e0c2b0cc2e71294cd86916807fef62cb	d8b00929dec65d422303256336ada04f
52ee4c6902f6ead006b0fb2f3e2d7771	d8b00929dec65d422303256336ada04f
4f48e858e9ed95709458e17027bb94bf	76423d8352c9e8fc8d7d65f62c55eae9
e0de9c10bbf73520385ea5dcbdf62073	f75d91cdd36b85cc4a8dfeca4f24fa14
065b56757c6f6a0fba7ab0c64e4c1ae1	f75d91cdd36b85cc4a8dfeca4f24fa14
952dc6362e304f00575264e9d54d1fa6	d8b00929dec65d422303256336ada04f
5cd1c3c856115627b4c3e93991f2d9cd	f75d91cdd36b85cc4a8dfeca4f24fa14
0903a7e60f0eb20fdc8cc0b8dbd45526	1007e1b7f894dfbf72a0eaa80f3bc57e
32af59a47b8c7e1c982ae797fc491180	d8b00929dec65d422303256336ada04f
fb8be6409408481ad69166324bdade9c	f01fc92b23faa973f3492a23d5a705c5
bd4184ee062e4982b878b6b188793f5b	76423d8352c9e8fc8d7d65f62c55eae9
0020f19414b5f2874a0bfacd9d511b84	d8b00929dec65d422303256336ada04f
de12bbf91bc797df25ab4ae9cee1946b	d8b00929dec65d422303256336ada04f
237e378c239b44bff1e9a42ab866580c	1007e1b7f894dfbf72a0eaa80f3bc57e
89adcf990042dfdac7fd23685b3f1e37	d8b00929dec65d422303256336ada04f
44f2dc3400ce17fad32a189178ae72fa	ea71b362e3ea9969db085abfccdeb10d
3bd94845163385cecefc5265a2e5a525	d8b00929dec65d422303256336ada04f
0b0d1c3752576d666c14774b8233889f	4442e4af0916f53a07fb8ca9a49b98ed
a4902fb3d5151e823c74dfd51551b4b0	c8f4261f9f46e6465709e17ebea7a92b
99bd5eff92fc3ba728a9da5aa1971488	d8b00929dec65d422303256336ada04f
24ff2b4548c6bc357d9d9ab47882661e	d8b00929dec65d422303256336ada04f
776da10f7e18ffde35ea94d144dc60a3	c8f4261f9f46e6465709e17ebea7a92b
829922527f0e7d64a3cfda67e24351e3	d8b00929dec65d422303256336ada04f
bfc9ace5d2a11fae56d038d68c601f00	f75d91cdd36b85cc4a8dfeca4f24fa14
443866d78de61ab3cd3e0e9bf97a34f6	9891739094756d2605946c867b32ad28
b570e354b7ebc40e20029fcc7a15e5a7	f75d91cdd36b85cc4a8dfeca4f24fa14
7492a1ca2669793b485b295798f5d782	424214945ba5615eca039bfe5d731c09
63d7f33143522ba270cb2c87f724b126	424214945ba5615eca039bfe5d731c09
aa86b6fc103fc757e14f03afe6eb0c0a	d8b00929dec65d422303256336ada04f
6c607fc8c0adc99559bc14e01170fee1	f75d91cdd36b85cc4a8dfeca4f24fa14
91a337f89fe65fec1c97f52a821c1178	76423d8352c9e8fc8d7d65f62c55eae9
5ec1e9fa36898eaf6d1021be67e0d00c	d8b00929dec65d422303256336ada04f
8ce896355a45f5b9959eb676b8b5580c	d8b00929dec65d422303256336ada04f
bbce8e45250a239a252752fac7137e00	c8f4261f9f46e6465709e17ebea7a92b
baa9d4eef21c7b89f42720313b5812d4	76423d8352c9e8fc8d7d65f62c55eae9
2414366fe63cf7017444181acacb6347	0309a6c666a7a803fdb9db95de71cf01
1ac0c8e8c04cf2d6f02fdb8292e74588	9891739094756d2605946c867b32ad28
5f992768f7bb9592bed35b07197c87d0	d8b00929dec65d422303256336ada04f
ca5a010309ffb20190558ec20d97e5b2	d5b9290a0b67727d4ba1ca6059dc31a6
f644bd92037985f8eb20311bc6d5ed94	d8b00929dec65d422303256336ada04f
a825b2b87f3b61c9660b81f340f6e519	0309a6c666a7a803fdb9db95de71cf01
891a55e21dfacf2f97c450c77e7c3ea7	f75d91cdd36b85cc4a8dfeca4f24fa14
ef6369d9794dbe861a56100e92a3c71d	c8f4261f9f46e6465709e17ebea7a92b
73affe574e6d4dc2fa72b46dc9dd4815	f01fc92b23faa973f3492a23d5a705c5
649db5c9643e1c17b3a44579980da0ad	a67d4cbdd1b59e0ffccc6bafc83eb033
1e8563d294da81043c2772b36753efaf	d8b00929dec65d422303256336ada04f
362f8cdd1065b0f33e73208eb358991d	d8b00929dec65d422303256336ada04f
820de5995512273916b117944d6da15a	445d337b5cd5de476f99333df6b0c2a7
d39d7a2bb6d430fd238a6aedc7f0cee2	d8b00929dec65d422303256336ada04f
6d57b25c282247075f5e03cde27814df	d8b00929dec65d422303256336ada04f
bbb668ff900efa57d936e726a09e4fe8	6f781c6559a0c605da918096bdb69edf
2501f7ba78cc0fd07efb7c17666ff12e	a67d4cbdd1b59e0ffccc6bafc83eb033
76700087e932c3272e05694610d604ba	6c1674d14bf5f95742f572cddb0641a7
9b1088b616414d0dc515ab1f2b4922f1	d8b00929dec65d422303256336ada04f
dfdef9b5190f331de20fe029babf032e	d8b00929dec65d422303256336ada04f
4cfab0d66614c6bb6d399837656c590e	a67d4cbdd1b59e0ffccc6bafc83eb033
5b22d1d5846a2b6b6d0cf342e912d124	d8b00929dec65d422303256336ada04f
710ba5ed112368e3ce50e2c84b17210c	c8f4261f9f46e6465709e17ebea7a92b
4261335bcdc95bd89fd530ba35afbf4c	d8b00929dec65d422303256336ada04f
2cfe35095995e8dd15ab7b867e178c15	0309a6c666a7a803fdb9db95de71cf01
2cf65e28c586eeb98daaecf6eb573e7a	6f781c6559a0c605da918096bdb69edf
3cdb47307aeb005121b09c41c8d8bee6	d8b00929dec65d422303256336ada04f
53407737e93f53afdfc588788b8288e8	d8b00929dec65d422303256336ada04f
006fc2724417174310cf06d2672e34d2	d8b00929dec65d422303256336ada04f
7db066b46f48d010fdb8c87337cdeda4	f75d91cdd36b85cc4a8dfeca4f24fa14
a3f5542dc915b94a5e10dab658bb0959	c8f4261f9f46e6465709e17ebea7a92b
2ac79000a90b015badf6747312c0ccad	d8b00929dec65d422303256336ada04f
eb2c788da4f36fba18b85ae75aff0344	c8f4261f9f46e6465709e17ebea7a92b
626dceb92e4249628c1e76a2c955cd24	d8b00929dec65d422303256336ada04f
8fda25275801e4a40df6c73078baf753	d5b9290a0b67727d4ba1ca6059dc31a6
3a2a7f86ca87268be9b9e0557b013565	d8b00929dec65d422303256336ada04f
ac03fad3be179a237521ec4ef2620fb0	d8b00929dec65d422303256336ada04f
8b0ee5a501cef4a5699fd3b2d4549e8f	f75d91cdd36b85cc4a8dfeca4f24fa14
7e2b83d69e6c93adf203e13bc7d6f444	d8b00929dec65d422303256336ada04f
0fbddeb130361265f1ba6f86b00f0968	d8b00929dec65d422303256336ada04f
3f15c445cb553524b235b01ab75fe9a6	f75d91cdd36b85cc4a8dfeca4f24fa14
656d1497f7e25fe0559c6be81a4bccae	f75d91cdd36b85cc4a8dfeca4f24fa14
f60ab90d94b9cafe6b32f6a93ee8fcda	f75d91cdd36b85cc4a8dfeca4f24fa14
8775f64336ee5e9a8114fbe3a5a628c5	424214945ba5615eca039bfe5d731c09
e872b77ff7ac24acc5fa373ebe9bb492	8dbb07a18d46f63d8b3c8994d5ccc351
f0e1f32b93f622ea3ddbf6b55b439812	d8b00929dec65d422303256336ada04f
53a0aafa942245f18098ccd58b4121aa	d8b00929dec65d422303256336ada04f
0780d2d1dbd538fec3cdd8699b08ea02	d8b00929dec65d422303256336ada04f
4a45ac6d83b85125b4163a40364e7b2c	ea71b362e3ea9969db085abfccdeb10d
58db028cf01dd425e5af6c7d511291c1	d8b00929dec65d422303256336ada04f
2252d763a2a4ac815b122a0176e3468f	d8b00929dec65d422303256336ada04f
11d396b078f0ae37570c8ef0f45937ad	d8b00929dec65d422303256336ada04f
585b13106ecfd7ede796242aeaed4ea8	d8b00929dec65d422303256336ada04f
6c1fcd3c91bc400e5c16f467d75dced3	d8b00929dec65d422303256336ada04f
a7f9797e4cd716e1516f9d4845b0e1e2	f75d91cdd36b85cc4a8dfeca4f24fa14
7d878673694ff2498fbea0e5ba27e0ea	d8b00929dec65d422303256336ada04f
0844ad55f17011abed4a5208a3a05b74	76423d8352c9e8fc8d7d65f62c55eae9
6738f9acd4740d945178c649d6981734	6c1674d14bf5f95742f572cddb0641a7
fd85bfffd5a0667738f6110281b25db8	d8b00929dec65d422303256336ada04f
33f03dd57f667d41ac77c6baec352a81	d8b00929dec65d422303256336ada04f
3509af6be9fe5defc1500f5c77e38563	d8b00929dec65d422303256336ada04f
0640cfbf1d269b69c535ea4e288dfd96	d8b00929dec65d422303256336ada04f
a716390764a4896d99837e99f9e009c9	42537f0fb56e31e20ab9c2305752087d
e74a88c71835c14d92d583a1ed87cc6c	c8f4261f9f46e6465709e17ebea7a92b
3d6ff25ab61ad55180a6aee9b64515bf	f75d91cdd36b85cc4a8dfeca4f24fa14
36648510adbf2a3b2028197a60b5dada	d8b00929dec65d422303256336ada04f
eb3bfb5a3ccdd4483aabc307ae236066	d8b00929dec65d422303256336ada04f
1ebd63d759e9ff532d5ce63ecb818731	d8b00929dec65d422303256336ada04f
1c06fc6740d924cab33dce73643d84b9	4442e4af0916f53a07fb8ca9a49b98ed
4a2a0d0c29a49d9126dcb19230aa1994	0309a6c666a7a803fdb9db95de71cf01
059792b70fc0686fb296e7fcae0bda50	d8b00929dec65d422303256336ada04f
7dfe9aa0ca5bb31382879ccd144cc3ae	d8b00929dec65d422303256336ada04f
a650d82df8ca65bb69a45242ab66b399	6f781c6559a0c605da918096bdb69edf
3dda886448fe98771c001b56a4da9893	3ad08396dc5afa78f34f548eea3c1d64
d73310b95e8b4dece44e2a55dd1274e6	c8f4261f9f46e6465709e17ebea7a92b
fb28e62c0e801a787d55d97615e89771	d8b00929dec65d422303256336ada04f
652208d2aa8cdd769632dbaeb7a16358	d8b00929dec65d422303256336ada04f
660813131789b822f0c75c667e23fc85	f75d91cdd36b85cc4a8dfeca4f24fa14
b5f7b25b0154c34540eea8965f90984d	d5b9290a0b67727d4ba1ca6059dc31a6
a7a9c1b4e7f10bd1fdf77aff255154f7	f75d91cdd36b85cc4a8dfeca4f24fa14
e64d38b05d197d60009a43588b2e4583	76423d8352c9e8fc8d7d65f62c55eae9
88711444ece8fe638ae0fb11c64e2df3	76423d8352c9e8fc8d7d65f62c55eae9
278c094627c0dd891d75ea7a3d0d021e	d8b00929dec65d422303256336ada04f
0a56095b73dcbd2a76bb9d4831881cb3	d8b00929dec65d422303256336ada04f
ff578d3db4dc3311b3098c8365d54e6b	d8b00929dec65d422303256336ada04f
80fcd08f6e887f6cfbedd2156841ab2b	0309a6c666a7a803fdb9db95de71cf01
db38e12f9903b156f9dc91fce2ef3919	5feb168ca8fb495dcc89b1208cdeb919
90d127641ffe2a600891cd2e3992685b	3ad08396dc5afa78f34f548eea3c1d64
2e7a848dc99bd27acb36636124855faf	0c7d5ae44b2a0be9ebd7d6b9f7d60f20
79566192cda6b33a9ff59889eede2d66	f75d91cdd36b85cc4a8dfeca4f24fa14
3964d4f40b6166aa9d370855bd20f662	9891739094756d2605946c867b32ad28
4548a3b9c1e31cf001041dc0d166365b	d8b00929dec65d422303256336ada04f
450948d9f14e07ba5e3015c2d726b452	3ad08396dc5afa78f34f548eea3c1d64
c4678a2e0eef323aeb196670f2bc8a6e	a67d4cbdd1b59e0ffccc6bafc83eb033
c1923ca7992dc6e79d28331abbb64e72	4442e4af0916f53a07fb8ca9a49b98ed
5842a0c2470fe12ee3acfeec16c79c57	d8b00929dec65d422303256336ada04f
96682d9c9f1bed695dbf9176d3ee234c	d8b00929dec65d422303256336ada04f
7f29efc2495ce308a8f4aa7bfc11d701	f75d91cdd36b85cc4a8dfeca4f24fa14
12e93f5fab5f7d16ef37711ef264d282	d8b00929dec65d422303256336ada04f
4094ffd492ba473a2a7bea1b19b1662d	d8b00929dec65d422303256336ada04f
02d44fbbe1bfacd6eaa9b20299b1cb78	a67d4cbdd1b59e0ffccc6bafc83eb033
9ab8f911c74597493400602dc4d2b412	d8b00929dec65d422303256336ada04f
11f8d9ec8f6803ea61733840f13bc246	6542f875eaa09a5c550e5f3986400ad9
54f0b93fa83225e4a712b70c68c0ab6f	d8b00929dec65d422303256336ada04f
1cdd53cece78d6e8dffcf664fa3d1be2	d8b00929dec65d422303256336ada04f
1e88302efcfc873691f0c31be4e2a388	d8b00929dec65d422303256336ada04f
2af9e4497582a6faa68a42ac2d512735	f75d91cdd36b85cc4a8dfeca4f24fa14
13caf3d14133dfb51067264d857eaf70	d8b00929dec65d422303256336ada04f
1e14d6b40d8e81d8d856ba66225dcbf3	2ff6e535bd2f100979a171ad430e642b
5b20ea1312a1a21beaa8b86fe3a07140	f75d91cdd36b85cc4a8dfeca4f24fa14
fa03eb688ad8aa1db593d33dabd89bad	51802d8bb965d0e5be697f07d16922e8
7a4fafa7badd04d5d3114ab67b0caf9d	d8b00929dec65d422303256336ada04f
4cabe475dd501f3fd4da7273b5890c33	3ad08396dc5afa78f34f548eea3c1d64
f8e7112b86fcd9210dfaf32c00d6d375	76423d8352c9e8fc8d7d65f62c55eae9
91c9ed0262dea7446a4f3a3e1cdd0698	6f781c6559a0c605da918096bdb69edf
79ce9bd96a3184b1ee7c700aa2927e67	6c1674d14bf5f95742f572cddb0641a7
218f2bdae8ad3bb60482b201e280ffdc	76423d8352c9e8fc8d7d65f62c55eae9
4927f3218b038c780eb795766dfd04ee	d8b00929dec65d422303256336ada04f
0a97b893b92a7df612eadfe97589f242	d8b00929dec65d422303256336ada04f
31d8a0a978fad885b57a685b1a0229df	9891739094756d2605946c867b32ad28
7ef36a3325a61d4f1cff91acbe77c7e3	d8b00929dec65d422303256336ada04f
5b709b96ee02a30be5eee558e3058245	42537f0fb56e31e20ab9c2305752087d
19baf8a6a25030ced87cd0ce733365a9	ea71b362e3ea9969db085abfccdeb10d
4ee21b1371ba008a26b313c7622256f8	d8b00929dec65d422303256336ada04f
91b18e22d4963b216af00e1dd43b5d05	0309a6c666a7a803fdb9db95de71cf01
6bd19bad2b0168d4481b19f9c25b4a9f	1007e1b7f894dfbf72a0eaa80f3bc57e
53369c74c3cacdc38bdcdeda9284fe3c	5feb168ca8fb495dcc89b1208cdeb919
6bafe8cf106c32d485c469d36c056989	f75d91cdd36b85cc4a8dfeca4f24fa14
66599a31754b5ac2a202c46c2b577c8e	f75d91cdd36b85cc4a8dfeca4f24fa14
4453eb658c6a304675bd52ca75fbae6d	d8b00929dec65d422303256336ada04f
5e4317ada306a255748447aef73fff68	f75d91cdd36b85cc4a8dfeca4f24fa14
65976b6494d411d609160a2dfd98f903	76423d8352c9e8fc8d7d65f62c55eae9
360c000b499120147c8472998859a9fe	d8b00929dec65d422303256336ada04f
e62a773154e1179b0cc8c5592207cb10	445d337b5cd5de476f99333df6b0c2a7
4bb93d90453dd63cc1957a033f7855c7	d8b00929dec65d422303256336ada04f
121189969c46f49b8249633c2d5a7bfa	f75d91cdd36b85cc4a8dfeca4f24fa14
f29d276fd930f1ad7687ed7e22929b64	06630c890abadde9228ea818ce52b621
249229ca88aa4a8815315bb085cf4d61	f75d91cdd36b85cc4a8dfeca4f24fa14
c05d504b806ad065c9b548c0cb1334cd	d8b00929dec65d422303256336ada04f
b96a3cb81197e8308c87f6296174fe3e	d8b00929dec65d422303256336ada04f
8edf4531385941dfc85e3f3d3e32d24f	c8f4261f9f46e6465709e17ebea7a92b
90d523ebbf276f516090656ebfccdc9f	b78edab0f52e0d6c195fd0d8c5709d26
94ca28ea8d99549c2280bcc93f98c853	a67d4cbdd1b59e0ffccc6bafc83eb033
076365679712e4206301117486c3d0ec	f75d91cdd36b85cc4a8dfeca4f24fa14
abd7ab19ff758cf4c1a2667e5bbac444	51802d8bb965d0e5be697f07d16922e8
0af74c036db52f48ad6cbfef6fee2999	6f781c6559a0c605da918096bdb69edf
095849fbdc267416abc6ddb48be311d7	d8b00929dec65d422303256336ada04f
72778afd2696801f5f3a1f35d0e4e357	d8b00929dec65d422303256336ada04f
5c0adc906f34f9404d65a47eea76dac0	d8b00929dec65d422303256336ada04f
fdcf3cdc04f367257c92382e032b6293	d8b00929dec65d422303256336ada04f
8bc31f7cc79c177ab7286dda04e2d1e5	f75d91cdd36b85cc4a8dfeca4f24fa14
88dd124c0720845cba559677f3afa15d	d8b00929dec65d422303256336ada04f
2df8905eae6823023de6604dc5346c29	6b718641741f992e68ec3712718561b8
7e0d5240ec5d34a30b6f24909e5edcb4	f75d91cdd36b85cc4a8dfeca4f24fa14
f4f870098db58eeae93742dd2bcaf2b2	d8b00929dec65d422303256336ada04f
d433b7c1ce696b94a8d8f72de6cfbeaa	d8b00929dec65d422303256336ada04f
28bb59d835e87f3fd813a58074ca0e11	d8b00929dec65d422303256336ada04f
aa0d528ba11ea1485d466dfe1ea40819	d8b00929dec65d422303256336ada04f
bbc155fb2b111bf61c4f5ff892915e6b	33cac763789c407f405b2cf0dce7df89
f953fa7b33e7b6503f4380895bbe41c8	f75d91cdd36b85cc4a8dfeca4f24fa14
cafe9e68e8f90b3e1328da8858695b31	d8b00929dec65d422303256336ada04f
ad62209fb63910acf40280cea3647ec5	d8b00929dec65d422303256336ada04f
0a267617c0b5b4d53e43a7d4e4c522ad	a67d4cbdd1b59e0ffccc6bafc83eb033
058fcf8b126253956deb3ce672d107a7	f75d91cdd36b85cc4a8dfeca4f24fa14
b14814d0ee12ffadc8f09ab9c604a9d0	f75d91cdd36b85cc4a8dfeca4f24fa14
5447110e1e461c8c22890580c796277a	f75d91cdd36b85cc4a8dfeca4f24fa14
9e84832a15f2698f67079a3224c2b6fb	d8b00929dec65d422303256336ada04f
4a7d9e528dada8409e88865225fb27c4	d8b00929dec65d422303256336ada04f
d3e98095eeccaa253050d67210ef02bb	d8b00929dec65d422303256336ada04f
c3490492512b7fe65cdb0c7305044675	d8b00929dec65d422303256336ada04f
e61e30572fd58669ae9ea410774e0eb6	d8b00929dec65d422303256336ada04f
990813672e87b667add44c712bb28d3d	ea71b362e3ea9969db085abfccdeb10d
8143ee8032c71f6f3f872fc5bb2a4fed	9891739094756d2605946c867b32ad28
485065ad2259054abf342d7ae3fe27e6	d8b00929dec65d422303256336ada04f
278606b1ac0ae7ef86e86342d1f259c3	d8b00929dec65d422303256336ada04f
a538bfe6fe150a92a72d78f89733dbd0	d8b00929dec65d422303256336ada04f
c127f32dc042184d12b8c1433a77e8c4	b78edab0f52e0d6c195fd0d8c5709d26
e4b3296f8a9e2a378eb3eb9576b91a37	2e6507f70a9cc26fb50f5fd82a83c7ef
09d8e20a5368ce1e5c421a04cb566434	d8b00929dec65d422303256336ada04f
4366d01be1b2ddef162fc0ebb6933508	d8b00929dec65d422303256336ada04f
46174766ce49edbbbc40e271c87b5a83	ef3388cc5659bccb742fb8af762f1bfd
4fa857a989df4e1deea676a43dceea07	d8b00929dec65d422303256336ada04f
36cbc41c1c121f2c68f5776a118ea027	6f781c6559a0c605da918096bdb69edf
da867941c8bacf9be8e59bc13d765f92	f75d91cdd36b85cc4a8dfeca4f24fa14
6ee2e6d391fa98d7990b502e72c7ec58	d8b00929dec65d422303256336ada04f
a4977b96c7e5084fcce21a0d07b045f8	c8f4261f9f46e6465709e17ebea7a92b
1da77fa5b97c17be83cc3d0693c405cf	f75d91cdd36b85cc4a8dfeca4f24fa14
e0f39406f0e15487dd9d3997b2f5ca61	d8b00929dec65d422303256336ada04f
399033f75fcf47d6736c9c5209222ab8	d8b00929dec65d422303256336ada04f
6f195d8f9fe09d45d2e680f7d7157541	b78edab0f52e0d6c195fd0d8c5709d26
2113f739f81774557041db616ee851e6	c8f4261f9f46e6465709e17ebea7a92b
32814ff4ca9a26b8d430a8c0bc8dc63e	d8b00929dec65d422303256336ada04f
e29ef4beb480eab906ffa7c05aeec23d	94880bda83bda77c5692876700711f15
2447873ddeeecaa165263091c0cbb22f	d8b00929dec65d422303256336ada04f
86482a1e94052aa18cd803a51104cdb9	f75d91cdd36b85cc4a8dfeca4f24fa14
fcd1c1b547d03e760d1defa4d2b98783	d8b00929dec65d422303256336ada04f
6369ba49db4cf35b35a7c47e3d4a4fd0	d8b00929dec65d422303256336ada04f
935b48a84528c4280ec208ce529deea0	76423d8352c9e8fc8d7d65f62c55eae9
52b133bfecec2fba79ecf451de3cf3bb	d8b00929dec65d422303256336ada04f
559ccea48c3460ebc349587d35e808dd	c8f4261f9f46e6465709e17ebea7a92b
8e11b2f987a99ed900a44aa1aa8bd3d0	a67d4cbdd1b59e0ffccc6bafc83eb033
59f06d56c38ac98effb4c6da117b0305	f75d91cdd36b85cc4a8dfeca4f24fa14
804803e43d2c779d00004a6e87f28e30	f75d91cdd36b85cc4a8dfeca4f24fa14
f042da2a954a1521114551a6f9e22c75	d8b00929dec65d422303256336ada04f
b1d465aaf3ccf8701684211b1623adf2	8189ecf686157db0c0274c1f49373318
4f840b1febbbcdb12b9517cd0a91e8f4	6c1674d14bf5f95742f572cddb0641a7
c2855b6617a1b08fed3824564e15a653	f75d91cdd36b85cc4a8dfeca4f24fa14
405c7f920b019235f244315a564a8aed	d8b00929dec65d422303256336ada04f
8e62fc75d9d0977d0be4771df05b3c2f	6f781c6559a0c605da918096bdb69edf
cd9483c1733b17f57d11a77c9404893c	f75d91cdd36b85cc4a8dfeca4f24fa14
3656edf3a40a25ccd00d414c9ecbb635	d8b00929dec65d422303256336ada04f
6d89517dbd1a634b097f81f5bdbb07a2	d8b00929dec65d422303256336ada04f
db46d9a37b31baa64cb51604a2e4939a	00247297c394dd443dc97067830c35f4
5af874093e5efcbaeb4377b84c5f2ec5	d8b00929dec65d422303256336ada04f
8a6f1a01e4b0d9e272126a8646a72088	6f781c6559a0c605da918096bdb69edf
5037c1968f3b239541c546d32dec39eb	d8b00929dec65d422303256336ada04f
3e52c77d795b7055eeff0c44687724a1	3ad08396dc5afa78f34f548eea3c1d64
5952dff7a6b1b3c94238ad3c6a42b904	f75d91cdd36b85cc4a8dfeca4f24fa14
deaccc41a952e269107cc9a507dfa131	d8b00929dec65d422303256336ada04f
bb4cc149e8027369e71eb1bb36cd98e0	f75d91cdd36b85cc4a8dfeca4f24fa14
754230e2c158107a2e93193c829e9e59	907eba32d950bfab68227fd7ea22999b
a29c1c4f0a97173007be3b737e8febcc	d8b00929dec65d422303256336ada04f
4fab532a185610bb854e0946f4def6a4	d8b00929dec65d422303256336ada04f
e25ee917084bdbdc8506b56abef0f351	0309a6c666a7a803fdb9db95de71cf01
e6fd7b62a39c109109d33fcd3b5e129d	d8b00929dec65d422303256336ada04f
da29e297c23e7868f1d50ec5a6a4359b	d8b00929dec65d422303256336ada04f
96048e254d2e02ba26f53edd271d3f88	d8b00929dec65d422303256336ada04f
c2275e8ac71d308946a63958bc7603a1	d8b00929dec65d422303256336ada04f
dde3e0b0cc344a7b072bbab8c429f4ff	42537f0fb56e31e20ab9c2305752087d
b785a5ffad5e7e36ccac25c51d5d8908	d8b00929dec65d422303256336ada04f
3bcbddf6c114327fc72ea06bcb02f9ef	8189ecf686157db0c0274c1f49373318
63c0a328ae2bee49789212822f79b83f	d8b00929dec65d422303256336ada04f
f03bde11d261f185cbacfa32c1c6538c	51802d8bb965d0e5be697f07d16922e8
f6540bc63be4c0cb21811353c0d24f69	a67d4cbdd1b59e0ffccc6bafc83eb033
e4f0ad5ef0ac3037084d8a5e3ca1cabc	a67d4cbdd1b59e0ffccc6bafc83eb033
ea16d031090828264793e860a00cc995	a67d4cbdd1b59e0ffccc6bafc83eb033
5eed658c4b7b68a0ecc49205b68d54e7	d8b00929dec65d422303256336ada04f
a0fb30950d2a150c1d2624716f216316	9891739094756d2605946c867b32ad28
4ad6c928711328d1cf0167bc87079a14	94880bda83bda77c5692876700711f15
96e3cdb363fe6df2723be5b994ad117a	0309a6c666a7a803fdb9db95de71cf01
c8d551145807972d194691247e7102a2	f75d91cdd36b85cc4a8dfeca4f24fa14
45b568ce63ea724c415677711b4328a7	424214945ba5615eca039bfe5d731c09
145bd9cf987b6f96fa6f3b3b326303c9	d8b00929dec65d422303256336ada04f
c238980432ab6442df9b2c6698c43e47	d8b00929dec65d422303256336ada04f
39a25b9c88ce401ca54fd7479d1c8b73	9891739094756d2605946c867b32ad28
8cadf0ad04644ce2947bf3aa2817816e	d8b00929dec65d422303256336ada04f
85fac49d29a31f1f9a8a18d6b04b9fc9	d8b00929dec65d422303256336ada04f
b81ee269be538a500ed057b3222c86a2	d8b00929dec65d422303256336ada04f
cf71a88972b5e06d8913cf53c916e6e4	d8b00929dec65d422303256336ada04f
5518086aebc9159ba7424be0073ce5c9	d8b00929dec65d422303256336ada04f
60f28c7011b5e32d220cbaa0e563291b	d8b00929dec65d422303256336ada04f
6eaeee13a99072e69bab1f707b79c56a	d8b00929dec65d422303256336ada04f
2c4e2c9948ddac6145e529c2ae7296da	0309a6c666a7a803fdb9db95de71cf01
c9af1c425ca093648e919c2e471df3bd	a67d4cbdd1b59e0ffccc6bafc83eb033
0291e38d9a3d398052be0ca52a7b1592	6c1674d14bf5f95742f572cddb0641a7
8852173e80d762d62f0bcb379d82ebdb	76423d8352c9e8fc8d7d65f62c55eae9
000f49c98c428aff4734497823d04f45	c8f4261f9f46e6465709e17ebea7a92b
dea293bdffcfb292b244b6fe92d246dc	6f781c6559a0c605da918096bdb69edf
302ebe0389198972c223f4b72894780a	d8b00929dec65d422303256336ada04f
ac62ad2816456aa712809bf01327add1	d8b00929dec65d422303256336ada04f
470f3f69a2327481d26309dc65656f44	d8b00929dec65d422303256336ada04f
e254616b4a5bd5aaa54f90a3985ed184	d8b00929dec65d422303256336ada04f
3c5c578b7cf5cc0d23c1730d1d51436a	d8b00929dec65d422303256336ada04f
eaeaed2d9f3137518a5c8c7e6733214f	d8b00929dec65d422303256336ada04f
8ccd65d7f0f028405867991ae3eaeb56	d8b00929dec65d422303256336ada04f
781acc7e58c9a746d58f6e65ab1e90c4	9891739094756d2605946c867b32ad28
e5a674a93987de4a52230105907fffe9	d8b00929dec65d422303256336ada04f
a2459c5c8a50215716247769c3dea40b	c8f4261f9f46e6465709e17ebea7a92b
e285e4ecb358b92237298f67526beff7	d8b00929dec65d422303256336ada04f
d832b654664d104f0fbb9b6674a09a11	d8b00929dec65d422303256336ada04f
2aeb128c6d3eb7e79acb393b50e1cf7b	d8b00929dec65d422303256336ada04f
213c449bd4bcfcdb6bffecf55b2c30b4	d8b00929dec65d422303256336ada04f
4ea353ae22a1c0d26327638f600aeac8	d8b00929dec65d422303256336ada04f
66244bb43939f81c100f03922cdc3439	c8f4261f9f46e6465709e17ebea7a92b
\.


--
-- Data for Name: bands_events; Type: TABLE DATA; Schema: music; Owner: postgres
--

COPY music.bands_events (id_band, id_event) FROM stdin;
0020f19414b5f2874a0bfacd9d511b84	6b09e6ae26a0d03456b17df4c0964a2f
0020f19414b5f2874a0bfacd9d511b84	d5cd210a82be3dd1a7879b83ba5657c0
0020f19414b5f2874a0bfacd9d511b84	f8549f73852c778caa3e9c09558739f2
006fc2724417174310cf06d2672e34d2	084c45f4c0bf86930df25ae1c59b3fe6
02d44fbbe1bfacd6eaa9b20299b1cb78	633f06bd0bd191373d667af54af0939b
058fcf8b126253956deb3ce672d107a7	63a722e7e0aa4866721305fab1342530
058fcf8b126253956deb3ce672d107a7	9e829f734a90920dd15d3b93134ee270
059792b70fc0686fb296e7fcae0bda50	084c45f4c0bf86930df25ae1c59b3fe6
0640cfbf1d269b69c535ea4e288dfd96	7e2e7fa5ce040664bf7aaaef1cebd897
065b56757c6f6a0fba7ab0c64e4c1ae1	0a85beacde1a467e23452f40b4710030
06efe152a554665e02b8dc4f620bf3f1	42c7a1c1e7836f74ced153a27d98cef0
076365679712e4206301117486c3d0ec	ec9a23a8132c85ca37af85c69a2743c5
0780d2d1dbd538fec3cdd8699b08ea02	ff3bed6eb88bb82b3a77ddaf50933689
0844ad55f17011abed4a5208a3a05b74	8640cd270510da320a9dd71429b95531
0903a7e60f0eb20fdc8cc0b8dbd45526	dae84dc2587a374c667d0ba291f33481
095849fbdc267416abc6ddb48be311d7	a7fe0b5f5ae6fbfa811d754074e03d95
09d8e20a5368ce1e5c421a04cb566434	2a6b51056784227b35e412c444f54359
0a267617c0b5b4d53e43a7d4e4c522ad	a7fe0b5f5ae6fbfa811d754074e03d95
0a56095b73dcbd2a76bb9d4831881cb3	ff3bed6eb88bb82b3a77ddaf50933689
0a7ba3f35a9750ff956dca1d548dad12	f5a56d2eb1cd18bf3059cc15519097ea
0a97b893b92a7df612eadfe97589f242	00f269da8a1eee6c08cebcc093968ee1
0af74c036db52f48ad6cbfef6fee2999	dae84dc2587a374c667d0ba291f33481
0b0d1c3752576d666c14774b8233889f	cc4617b9ce3c2eee5d1e566eb2fbb1f6
0b6e98d660e2901c33333347da37ad36	abefb7041d2488eadeedba9a0829b753
0cdf051c93865faa15cbc5cd3d2b69fb	0aa506a505f1115202f993ee4d650480
0e2ea6aa669710389cf4d6e2ddf408c4	0a85beacde1a467e23452f40b4710030
0fbddeb130361265f1ba6f86b00f0968	a7fe0b5f5ae6fbfa811d754074e03d95
1056b63fdc3c5015cc4591aa9989c14f	1ea2f5c46c57c12dea2fed56cb87566f
1056b63fdc3c5015cc4591aa9989c14f	20b7e40ecd659c47ca991e0d420a54eb
1056b63fdc3c5015cc4591aa9989c14f	53812183e083ed8a87818371d6b3dbfb
1056b63fdc3c5015cc4591aa9989c14f	abefb7041d2488eadeedba9a0829b753
108c58fc39b79afc55fac7d9edf4aa2a	43bcb284a3d1a0eea2c7923d45b7f14e
108c58fc39b79afc55fac7d9edf4aa2a	64896cd59778f32b1c61561a21af6598
108c58fc39b79afc55fac7d9edf4aa2a	ec9a23a8132c85ca37af85c69a2743c5
10d91715ea91101cfe0767c812da8151	1104831a0d0fe7d2a6a4198c781e0e0d
1104831a0d0fe7d2a6a4198c781e0e0d	1104831a0d0fe7d2a6a4198c781e0e0d
1104831a0d0fe7d2a6a4198c781e0e0d	372ca4be7841a47ba693d4de7d220981
11635778f116ce6922f6068638a39028	1fad423d9d1f48b7bd6d31c8d5cb17ed
11d396b078f0ae37570c8ef0f45937ad	96a0774b50f0698d1245f287bfe20223
11f8d9ec8f6803ea61733840f13bc246	189f11691712600d4e1b0bdb4122e8aa
1209f43dbecaba22f3514bf40135f991	53812183e083ed8a87818371d6b3dbfb
121189969c46f49b8249633c2d5a7bfa	42c7a1c1e7836f74ced153a27d98cef0
13caf3d14133dfb51067264d857eaf70	9e829f734a90920dd15d3b93134ee270
14ab730fe0172d780da6d9e5d432c129	abefb7041d2488eadeedba9a0829b753
1734b04cf734cb291d97c135d74b4b87	00da417154f2da39e79c9dcf4d7502fa
1734b04cf734cb291d97c135d74b4b87	f8ead2514f0df3c6e8ec84b992dd6e44
187ebdf7947f4b61e0725c93227676a4	060fd8422f03df6eca94da7605b3a9cd
19baf8a6a25030ced87cd0ce733365a9	a7fe0b5f5ae6fbfa811d754074e03d95
1ac0c8e8c04cf2d6f02fdb8292e74588	63a722e7e0aa4866721305fab1342530
1ac0c8e8c04cf2d6f02fdb8292e74588	abefb7041d2488eadeedba9a0829b753
1bc1f7348d79a353ea4f594de9dd1392	a72c5a8b761c2fc1097f162eeda5d5db
1c06fc6740d924cab33dce73643d84b9	f861455af8364fc3fe01aef3fc597905
1c6987adbe5ab3e4364685e8caed0f59	d2a4c05671f768ba487ad365d2a0fb6e
1cdd53cece78d6e8dffcf664fa3d1be2	189f11691712600d4e1b0bdb4122e8aa
1cdd53cece78d6e8dffcf664fa3d1be2	85c434b11120b4ba2f116e89843a594e
1cdd53cece78d6e8dffcf664fa3d1be2	b6aaab867e3c1c7bfe215d7db747e5d9
1cdd53cece78d6e8dffcf664fa3d1be2	f5a56d2eb1cd18bf3059cc15519097ea
1da77fa5b97c17be83cc3d0693c405cf	9e829f734a90920dd15d3b93134ee270
1e14d6b40d8e81d8d856ba66225dcbf3	abefb7041d2488eadeedba9a0829b753
1e8563d294da81043c2772b36753efaf	a72c5a8b761c2fc1097f162eeda5d5db
1e88302efcfc873691f0c31be4e2a388	488af8bdc554488b6c8854fae6ae8610
1e9413d4cc9af0ad12a6707776573ba0	00f269da8a1eee6c08cebcc093968ee1
1e9413d4cc9af0ad12a6707776573ba0	85c434b11120b4ba2f116e89843a594e
1e9413d4cc9af0ad12a6707776573ba0	d8f60019c8e6cdbb84839791fd989d81
1ebd63d759e9ff532d5ce63ecb818731	ca69aebb5919e75661d929c1fbd39582
2082a7d613f976e7b182a3fe80a28958	dae84dc2587a374c667d0ba291f33481
2113f739f81774557041db616ee851e6	633f06bd0bd191373d667af54af0939b
218f2bdae8ad3bb60482b201e280ffdc	a7fe0b5f5ae6fbfa811d754074e03d95
2252d763a2a4ac815b122a0176e3468f	d5cd210a82be3dd1a7879b83ba5657c0
237e378c239b44bff1e9a42ab866580c	a122cd22f946f0c229745d88d89b05bd
2414366fe63cf7017444181acacb6347	00f269da8a1eee6c08cebcc093968ee1
2447873ddeeecaa165263091c0cbb22f	f8549f73852c778caa3e9c09558739f2
249229ca88aa4a8815315bb085cf4d61	553a00f0c40ce1b1107f833da69988e4
249789ae53c239814de8e606ff717ec9	abefb7041d2488eadeedba9a0829b753
24ff2b4548c6bc357d9d9ab47882661e	3af7c6d148d216f13f66669acb8d5c59
2501f7ba78cc0fd07efb7c17666ff12e	d8f74ab86e77455ffbd398065ee109a8
264721f3fc2aee2d28dadcdff432dbc1	f68790d8b2f82aad75f0c27be554ee48
2672777b38bc4ce58c49cf4c82813a42	5e65cc6b7435c63dac4b2baf17ab5838
278606b1ac0ae7ef86e86342d1f259c3	1104831a0d0fe7d2a6a4198c781e0e0d
278c094627c0dd891d75ea7a3d0d021e	abefb7041d2488eadeedba9a0829b753
2876f7ecdae220b3c0dcb91ff13d0590	6b09e6ae26a0d03456b17df4c0964a2f
28a95ef0eabe44a27f49bbaecaa8a847	0a85beacde1a467e23452f40b4710030
28bb59d835e87f3fd813a58074ca0e11	d8f60019c8e6cdbb84839791fd989d81
28bc31b338dbd482802b77ed1fd82a50	d5cd210a82be3dd1a7879b83ba5657c0
28f843fa3a493a3720c4c45942ad970e	0a85beacde1a467e23452f40b4710030
28f843fa3a493a3720c4c45942ad970e	8368e0fd31972c67de1117fb0fe12268
28f843fa3a493a3720c4c45942ad970e	d2a4c05671f768ba487ad365d2a0fb6e
28f843fa3a493a3720c4c45942ad970e	d8f60019c8e6cdbb84839791fd989d81
2a024edafb06c7882e2e1f7b57f2f951	d2a4c05671f768ba487ad365d2a0fb6e
2aae4f711c09481c8353003202e05359	6b09e6ae26a0d03456b17df4c0964a2f
2ac79000a90b015badf6747312c0ccad	9afc751ca7f2d91d23c453b32fd21864
2ac79000a90b015badf6747312c0ccad	d5cd210a82be3dd1a7879b83ba5657c0
2ac79000a90b015badf6747312c0ccad	ec9a23a8132c85ca37af85c69a2743c5
2af9e4497582a6faa68a42ac2d512735	06e5f3d0d817c436d351a9cf1bf94dfa
2cf65e28c586eeb98daaecf6eb573e7a	dae84dc2587a374c667d0ba291f33481
2cfe35095995e8dd15ab7b867e178c15	abefb7041d2488eadeedba9a0829b753
2df8905eae6823023de6604dc5346c29	0aa506a505f1115202f993ee4d650480
2e7a848dc99bd27acb36636124855faf	00f269da8a1eee6c08cebcc093968ee1
2fa2f1801dd37d6eb9fe4e34a782e397	dae84dc2587a374c667d0ba291f33481
31d8a0a978fad885b57a685b1a0229df	a7fe0b5f5ae6fbfa811d754074e03d95
32814ff4ca9a26b8d430a8c0bc8dc63e	ff3bed6eb88bb82b3a77ddaf50933689
32af59a47b8c7e1c982ae797fc491180	189f11691712600d4e1b0bdb4122e8aa
32af59a47b8c7e1c982ae797fc491180	62f7101086340682e5bc58a86976cfb5
33b6f1b596a60fa87baef3d2c05b7c04	3f15c445cb553524b235b01ab75fe9a6
348bcdb386eb9cb478b55a7574622b7c	f5a56d2eb1cd18bf3059cc15519097ea
3509af6be9fe5defc1500f5c77e38563	f68790d8b2f82aad75f0c27be554ee48
360c000b499120147c8472998859a9fe	85c434b11120b4ba2f116e89843a594e
3614c45db20ee41e068c2ab7969eb3b5	2a6b51056784227b35e412c444f54359
362f8cdd1065b0f33e73208eb358991d	d2a4c05671f768ba487ad365d2a0fb6e
3656edf3a40a25ccd00d414c9ecbb635	a7fe0b5f5ae6fbfa811d754074e03d95
36648510adbf2a3b2028197a60b5dada	372ca4be7841a47ba693d4de7d220981
36cbc41c1c121f2c68f5776a118ea027	f5a56d2eb1cd18bf3059cc15519097ea
36f969b6aeff175204078b0533eae1a0	f861455af8364fc3fe01aef3fc597905
37f02eba79e0a3d29dfd6a4cf2f4d019	dae84dc2587a374c667d0ba291f33481
3964d4f40b6166aa9d370855bd20f662	abefb7041d2488eadeedba9a0829b753
39e83bc14e95fcbc05848fc33c30821f	a7fe0b5f5ae6fbfa811d754074e03d95
3a2a7f86ca87268be9b9e0557b013565	62f7101086340682e5bc58a86976cfb5
3af7c6d148d216f13f66669acb8d5c59	3af7c6d148d216f13f66669acb8d5c59
3af7c6d148d216f13f66669acb8d5c59	d5cd210a82be3dd1a7879b83ba5657c0
3bd94845163385cecefc5265a2e5a525	53812183e083ed8a87818371d6b3dbfb
3be3e956aeb5dc3b16285463e02af25b	6b09e6ae26a0d03456b17df4c0964a2f
3cdb47307aeb005121b09c41c8d8bee6	a626f2fb0794eeb25b074b4c43776634
3cdb47307aeb005121b09c41c8d8bee6	d1832e7b44502c04ec5819ef3085371a
3d01ff8c75214314c4ca768c30e6807b	0a85beacde1a467e23452f40b4710030
3d01ff8c75214314c4ca768c30e6807b	6d5c464f0c139d97e715c51b43983695
3d01ff8c75214314c4ca768c30e6807b	85c434b11120b4ba2f116e89843a594e
3d01ff8c75214314c4ca768c30e6807b	a122cd22f946f0c229745d88d89b05bd
3d2ff8abd980d730b2f4fd0abae52f60	3f15c445cb553524b235b01ab75fe9a6
3d6ff25ab61ad55180a6aee9b64515bf	0a85beacde1a467e23452f40b4710030
3dda886448fe98771c001b56a4da9893	a7fe0b5f5ae6fbfa811d754074e03d95
3e52c77d795b7055eeff0c44687724a1	6b09e6ae26a0d03456b17df4c0964a2f
3e75cd2f2f6733ea4901458a7ce4236d	a2cc2bc245b90654e721d7040c028647
3f15c445cb553524b235b01ab75fe9a6	3f15c445cb553524b235b01ab75fe9a6
401357e57c765967393ba391a338e89b	12e7b1918420daf69b976a5949f9ba85
401357e57c765967393ba391a338e89b	e1baa5fa38e1e6c824f2011f89475f03
405c7f920b019235f244315a564a8aed	0e4e0056244fb82f89e66904ad62fdaf
4094ffd492ba473a2a7bea1b19b1662d	20cf9df7281c50060aaf023e04fd5082
410d913416c022077c5c1709bf104d3c	1ea2f5c46c57c12dea2fed56cb87566f
42563d0088d6ac1a47648fc7621e77c6	f8549f73852c778caa3e9c09558739f2
4261335bcdc95bd89fd530ba35afbf4c	00f269da8a1eee6c08cebcc093968ee1
426fdc79046e281c5322161f011ce68c	0a85beacde1a467e23452f40b4710030
4276250c9b1b839b9508825303c5c5ae	189f11691712600d4e1b0bdb4122e8aa
4366d01be1b2ddef162fc0ebb6933508	1ea2f5c46c57c12dea2fed56cb87566f
4366d01be1b2ddef162fc0ebb6933508	f10fa26efffb6c69534e7b0f7890272d
44012166c6633196dc30563db3ffd017	62f7101086340682e5bc58a86976cfb5
443866d78de61ab3cd3e0e9bf97a34f6	372ca4be7841a47ba693d4de7d220981
4453eb658c6a304675bd52ca75fbae6d	d2a4c05671f768ba487ad365d2a0fb6e
449b4d758aa7151bc1bbb24c3ffb40bb	be95780f2b4fba1a76846b716e69ed6d
44b7bda13ac1febe84d8607ca8bbf439	0aa506a505f1115202f993ee4d650480
44f2dc3400ce17fad32a189178ae72fa	d3284558d8cda50eb33b5e5ce91da2af
450948d9f14e07ba5e3015c2d726b452	d3284558d8cda50eb33b5e5ce91da2af
4548a3b9c1e31cf001041dc0d166365b	0a85beacde1a467e23452f40b4710030
4548a3b9c1e31cf001041dc0d166365b	20cf9df7281c50060aaf023e04fd5082
457f098eeb8e1518008449e9b1cb580d	6b09e6ae26a0d03456b17df4c0964a2f
46174766ce49edbbbc40e271c87b5a83	d45cf5e6b7af0cee99b37f15b13360ed
47b23e889175dde5d6057db61cb52847	372ca4be7841a47ba693d4de7d220981
485065ad2259054abf342d7ae3fe27e6	d2a4c05671f768ba487ad365d2a0fb6e
4927f3218b038c780eb795766dfd04ee	6b09e6ae26a0d03456b17df4c0964a2f
49c4097bae6c6ea96f552e38cfb6c2d1	0a85beacde1a467e23452f40b4710030
4a2a0d0c29a49d9126dcb19230aa1994	2a6b51056784227b35e412c444f54359
4a45ac6d83b85125b4163a40364e7b2c	d3284558d8cda50eb33b5e5ce91da2af
4a7d9e528dada8409e88865225fb27c4	ca69aebb5919e75661d929c1fbd39582
4b503a03f3f1aec6e5b4d53dd8148498	d8f74ab86e77455ffbd398065ee109a8
4b98a8c164586e11779a0ef9421ad0ee	ec9a23a8132c85ca37af85c69a2743c5
4cabe475dd501f3fd4da7273b5890c33	a72c5a8b761c2fc1097f162eeda5d5db
4cfab0d66614c6bb6d399837656c590e	dae84dc2587a374c667d0ba291f33481
4dddd8579760abb62aa4b1910725e73c	f5a56d2eb1cd18bf3059cc15519097ea
4ee21b1371ba008a26b313c7622256f8	7126a50ce66fe18b84a7bfb3defea15f
4ee21b1371ba008a26b313c7622256f8	ca69aebb5919e75661d929c1fbd39582
4f48e858e9ed95709458e17027bb94bf	a61b878c2b563f289de2109fa0f42144
4f840b1febbbcdb12b9517cd0a91e8f4	e471494f42d963b13f025c0636c43763
4fa857a989df4e1deea676a43dceea07	a7fe0b5f5ae6fbfa811d754074e03d95
5037c1968f3b239541c546d32dec39eb	e471494f42d963b13f025c0636c43763
5194c60496c6f02e8b169de9a0aa542c	d2a4c05671f768ba487ad365d2a0fb6e
51fa80e44b7555c4130bd06c53f4835c	d45cf5e6b7af0cee99b37f15b13360ed
51fa80e44b7555c4130bd06c53f4835c	dae84dc2587a374c667d0ba291f33481
522b6c44eb0aedf4970f2990a2f2a812	5e45d87cab8e0b30fba4603b4821bfcd
529a1d385b4a8ca97ea7369477c7b6a7	d2a4c05671f768ba487ad365d2a0fb6e
52b133bfecec2fba79ecf451de3cf3bb	52b133bfecec2fba79ecf451de3cf3bb
52b133bfecec2fba79ecf451de3cf3bb	fcbfd4ea93701414772acad10ad93a5f
52ee4c6902f6ead006b0fb2f3e2d7771	0e4e0056244fb82f89e66904ad62fdaf
52ee4c6902f6ead006b0fb2f3e2d7771	a7ea7b6c1894204987ce4694c1febe03
52ee4c6902f6ead006b0fb2f3e2d7771	f10fa26efffb6c69534e7b0f7890272d
53369c74c3cacdc38bdcdeda9284fe3c	8224efe45b1d8a1ebc0b9fb0a5405ac6
53407737e93f53afdfc588788b8288e8	abefb7041d2488eadeedba9a0829b753
53a0aafa942245f18098ccd58b4121aa	abefb7041d2488eadeedba9a0829b753
5435326cf392e2cd8ad7768150cd5df6	a122cd22f946f0c229745d88d89b05bd
5447110e1e461c8c22890580c796277a	a72c5a8b761c2fc1097f162eeda5d5db
54b72f3169fea84731d3bcba785eac49	00da417154f2da39e79c9dcf4d7502fa
54b72f3169fea84731d3bcba785eac49	633f06bd0bd191373d667af54af0939b
54f0b93fa83225e4a712b70c68c0ab6f	4c90356614158305d8527b80886d2c1e
55159d04cc4faebd64689d3b74a94009	8224efe45b1d8a1ebc0b9fb0a5405ac6
559ccea48c3460ebc349587d35e808dd	633f06bd0bd191373d667af54af0939b
5842a0c2470fe12ee3acfeec16c79c57	00f269da8a1eee6c08cebcc093968ee1
585b13106ecfd7ede796242aeaed4ea8	ca69aebb5919e75661d929c1fbd39582
58db028cf01dd425e5af6c7d511291c1	00f269da8a1eee6c08cebcc093968ee1
58db028cf01dd425e5af6c7d511291c1	85c434b11120b4ba2f116e89843a594e
5952dff7a6b1b3c94238ad3c6a42b904	0e33f8fbbb12367a6e8159a3b096898a
59d153c1c2408b702189623231b7898a	4bc4f9db3d901e8efe90f60d85a0420d
59f06d56c38ac98effb4c6da117b0305	1fad423d9d1f48b7bd6d31c8d5cb17ed
59f06d56c38ac98effb4c6da117b0305	8224efe45b1d8a1ebc0b9fb0a5405ac6
5af874093e5efcbaeb4377b84c5f2ec5	d2a4c05671f768ba487ad365d2a0fb6e
5b20ea1312a1a21beaa8b86fe3a07140	c9a70f42ce4dcd82a99ed83a5117b890
5b22d1d5846a2b6b6d0cf342e912d124	d1ee83d5951b1668e95b22446c38ba1c
5b709b96ee02a30be5eee558e3058245	c8ee19d8e2f21851dc16db65d7b138bc
5c0adc906f34f9404d65a47eea76dac0	53812183e083ed8a87818371d6b3dbfb
5c0adc906f34f9404d65a47eea76dac0	ec9a23a8132c85ca37af85c69a2743c5
5cd1c3c856115627b4c3e93991f2d9cd	372ca4be7841a47ba693d4de7d220981
5ce10014f645da4156ddd2cd0965986e	1fad423d9d1f48b7bd6d31c8d5cb17ed
5ce10014f645da4156ddd2cd0965986e	ec9a23a8132c85ca37af85c69a2743c5
5df92b70e2855656e9b3ffdf313d7379	00f269da8a1eee6c08cebcc093968ee1
5e4317ada306a255748447aef73fff68	9afc751ca7f2d91d23c453b32fd21864
5ec1e9fa36898eaf6d1021be67e0d00c	0a85beacde1a467e23452f40b4710030
5efb7d24387b25d8325839be958d9adf	53812183e083ed8a87818371d6b3dbfb
5f992768f7bb9592bed35b07197c87d0	abefb7041d2488eadeedba9a0829b753
626dceb92e4249628c1e76a2c955cd24	a7fe0b5f5ae6fbfa811d754074e03d95
6369ba49db4cf35b35a7c47e3d4a4fd0	ec9a23a8132c85ca37af85c69a2743c5
63ad3072dc5472bb44c2c42ede26d90f	0a85beacde1a467e23452f40b4710030
63ad3072dc5472bb44c2c42ede26d90f	abefb7041d2488eadeedba9a0829b753
63ae1791fc0523f47bea9485ffec8b8c	d45cf5e6b7af0cee99b37f15b13360ed
63bd9a49dd18fbc89c2ec1e1b689ddda	0dcd062f5beffeaae2efae21ef9f3755
63d7f33143522ba270cb2c87f724b126	0a85beacde1a467e23452f40b4710030
63d7f33143522ba270cb2c87f724b126	633f06bd0bd191373d667af54af0939b
63d7f33143522ba270cb2c87f724b126	6b09e6ae26a0d03456b17df4c0964a2f
63d7f33143522ba270cb2c87f724b126	b6aaab867e3c1c7bfe215d7db747e5d9
649db5c9643e1c17b3a44579980da0ad	a7fe0b5f5ae6fbfa811d754074e03d95
652208d2aa8cdd769632dbaeb7a16358	a72c5a8b761c2fc1097f162eeda5d5db
656d1497f7e25fe0559c6be81a4bccae	633f06bd0bd191373d667af54af0939b
65976b6494d411d609160a2dfd98f903	0e33f8fbbb12367a6e8159a3b096898a
660813131789b822f0c75c667e23fc85	dae84dc2587a374c667d0ba291f33481
66599a31754b5ac2a202c46c2b577c8e	f5a56d2eb1cd18bf3059cc15519097ea
6738f9acd4740d945178c649d6981734	372ca4be7841a47ba693d4de7d220981
679eaa47efb2f814f2642966ee6bdfe1	a7ea7b6c1894204987ce4694c1febe03
6830afd7158930ca7d1959ce778eb681	dae84dc2587a374c667d0ba291f33481
6a0e9ce4e2da4f2cbcd1292fddaa0ac6	1fad423d9d1f48b7bd6d31c8d5cb17ed
6b7cf117ecf0fea745c4c375c1480cb5	633f06bd0bd191373d667af54af0939b
6bafe8cf106c32d485c469d36c056989	8224efe45b1d8a1ebc0b9fb0a5405ac6
6bafe8cf106c32d485c469d36c056989	a72c5a8b761c2fc1097f162eeda5d5db
6bd19bad2b0168d4481b19f9c25b4a9f	d5cd210a82be3dd1a7879b83ba5657c0
6c00bb1a64f660600a6c1545377f92dc	12e7b1918420daf69b976a5949f9ba85
6c1fcd3c91bc400e5c16f467d75dced3	dae84dc2587a374c667d0ba291f33481
6c607fc8c0adc99559bc14e01170fee1	f5a56d2eb1cd18bf3059cc15519097ea
6d3b28f48c848a21209a84452d66c0c4	2a6b51056784227b35e412c444f54359
6d57b25c282247075f5e03cde27814df	00f269da8a1eee6c08cebcc093968ee1
6ee2e6d391fa98d7990b502e72c7ec58	4c90356614158305d8527b80886d2c1e
6f195d8f9fe09d45d2e680f7d7157541	5e45d87cab8e0b30fba4603b4821bfcd
6f199e29c5782bd05a4fef98e7e41419	a2cc2bc245b90654e721d7040c028647
710ba5ed112368e3ce50e2c84b17210c	084c45f4c0bf86930df25ae1c59b3fe6
71e32909a1bec1edfc09aec09ca2ac17	6b09e6ae26a0d03456b17df4c0964a2f
721c28f4c74928cc9e0bb3fef345e408	5e45d87cab8e0b30fba4603b4821bfcd
721c28f4c74928cc9e0bb3fef345e408	c8ee19d8e2f21851dc16db65d7b138bc
721c28f4c74928cc9e0bb3fef345e408	f8ead2514f0df3c6e8ec84b992dd6e44
72778afd2696801f5f3a1f35d0e4e357	7126a50ce66fe18b84a7bfb3defea15f
73affe574e6d4dc2fa72b46dc9dd4815	64896cd59778f32b1c61561a21af6598
73affe574e6d4dc2fa72b46dc9dd4815	9418ebabb93c5c1f47a05666913ec6e4
7462f03404f29ea618bcc9d52de8e647	0a85beacde1a467e23452f40b4710030
7463543d784aa59ca86359a50ef58c8e	0a85beacde1a467e23452f40b4710030
7492a1ca2669793b485b295798f5d782	372ca4be7841a47ba693d4de7d220981
74b3b7be6ed71b946a151d164ad8ede5	0e4e0056244fb82f89e66904ad62fdaf
7533f96ec01fd81438833f71539c7d4e	372ca4be7841a47ba693d4de7d220981
75ab0270163731ee05f35640d56ef473	a72c5a8b761c2fc1097f162eeda5d5db
76700087e932c3272e05694610d604ba	f68790d8b2f82aad75f0c27be554ee48
776da10f7e18ffde35ea94d144dc60a3	43bcb284a3d1a0eea2c7923d45b7f14e
776da10f7e18ffde35ea94d144dc60a3	663ea93736c204faee5f6c339203be3e
776da10f7e18ffde35ea94d144dc60a3	dae84dc2587a374c667d0ba291f33481
7771012413f955f819866e517b275cb4	6b09e6ae26a0d03456b17df4c0964a2f
77f2b3ea9e4bd785f5ff322bae51ba07	dae84dc2587a374c667d0ba291f33481
79566192cda6b33a9ff59889eede2d66	63a722e7e0aa4866721305fab1342530
79ce9bd96a3184b1ee7c700aa2927e67	4bc4f9db3d901e8efe90f60d85a0420d
7a4fafa7badd04d5d3114ab67b0caf9d	dae84dc2587a374c667d0ba291f33481
7c7ab6fbcb47bd5df1e167ca28220ee9	ec9a23a8132c85ca37af85c69a2743c5
7c83727aa466b3b1b9d6556369714fcf	be95780f2b4fba1a76846b716e69ed6d
7cd7921da2e6aab79c441a0c2ffc969b	9418ebabb93c5c1f47a05666913ec6e4
7cd7921da2e6aab79c441a0c2ffc969b	ca69aebb5919e75661d929c1fbd39582
7d6b45c02283175f490558068d1fc81b	ca69aebb5919e75661d929c1fbd39582
7d878673694ff2498fbea0e5ba27e0ea	9418ebabb93c5c1f47a05666913ec6e4
7d878673694ff2498fbea0e5ba27e0ea	d2a4c05671f768ba487ad365d2a0fb6e
7d878673694ff2498fbea0e5ba27e0ea	dae84dc2587a374c667d0ba291f33481
7db066b46f48d010fdb8c87337cdeda4	63a722e7e0aa4866721305fab1342530
7df8865bbec157552b8a579e0ed9bfe3	42c7a1c1e7836f74ced153a27d98cef0
7dfe9aa0ca5bb31382879ccd144cc3ae	dd50d5dcc02ea12c31e0ff495891dc22
7e0d5240ec5d34a30b6f24909e5edcb4	1fad423d9d1f48b7bd6d31c8d5cb17ed
7e0d5240ec5d34a30b6f24909e5edcb4	42c7a1c1e7836f74ced153a27d98cef0
7e0d5240ec5d34a30b6f24909e5edcb4	dd50d5dcc02ea12c31e0ff495891dc22
7e2b83d69e6c93adf203e13bc7d6f444	85c434b11120b4ba2f116e89843a594e
7e2b83d69e6c93adf203e13bc7d6f444	d5cd210a82be3dd1a7879b83ba5657c0
7e2b83d69e6c93adf203e13bc7d6f444	dae84dc2587a374c667d0ba291f33481
7eaf9a47aa47f3c65595ae107feab05d	dae84dc2587a374c667d0ba291f33481
7ef36a3325a61d4f1cff91acbe77c7e3	4c90356614158305d8527b80886d2c1e
7f29efc2495ce308a8f4aa7bfc11d701	c5593cbec8087184815492eee880f9a8
7fc454efb6df96e012e0f937723d24aa	084c45f4c0bf86930df25ae1c59b3fe6
804803e43d2c779d00004a6e87f28e30	a72c5a8b761c2fc1097f162eeda5d5db
80fcd08f6e887f6cfbedd2156841ab2b	a72c5a8b761c2fc1097f162eeda5d5db
8143ee8032c71f6f3f872fc5bb2a4fed	a2cc2bc245b90654e721d7040c028647
820de5995512273916b117944d6da15a	060fd8422f03df6eca94da7605b3a9cd
820de5995512273916b117944d6da15a	663ea93736c204faee5f6c339203be3e
828d51c39c87aad9b1407d409fa58e36	f10fa26efffb6c69534e7b0f7890272d
829922527f0e7d64a3cfda67e24351e3	d8f60019c8e6cdbb84839791fd989d81
832dd1d8efbdb257c2c7d3e505142f48	372ca4be7841a47ba693d4de7d220981
8589a6a4d8908d7e8813e9a1c5693d70	189f11691712600d4e1b0bdb4122e8aa
86482a1e94052aa18cd803a51104cdb9	ec9a23a8132c85ca37af85c69a2743c5
8654991720656374d632a5bb0c20ff11	a61b878c2b563f289de2109fa0f42144
8775f64336ee5e9a8114fbe3a5a628c5	c9a70f42ce4dcd82a99ed83a5117b890
87ded0ea2f4029da0a0022000d59232b	cc4617b9ce3c2eee5d1e566eb2fbb1f6
87f44124fb8d24f4c832138baede45c7	939fec794a3b41bc213c4df0c66c96f5
87f44124fb8d24f4c832138baede45c7	dae84dc2587a374c667d0ba291f33481
88711444ece8fe638ae0fb11c64e2df3	00f269da8a1eee6c08cebcc093968ee1
887d6449e3544dca547a2ddba8f2d894	20cf9df7281c50060aaf023e04fd5082
889aaf9cd0894206af758577cf5cf071	060fd8422f03df6eca94da7605b3a9cd
88dd124c0720845cba559677f3afa15d	00f269da8a1eee6c08cebcc093968ee1
891a55e21dfacf2f97c450c77e7c3ea7	9e829f734a90920dd15d3b93134ee270
8945663993a728ab19a3853e5b820a42	4bc4f9db3d901e8efe90f60d85a0420d
8945663993a728ab19a3853e5b820a42	9afc751ca7f2d91d23c453b32fd21864
897edb97d775897f69fa168a88b01c19	06e5f3d0d817c436d351a9cf1bf94dfa
89adcf990042dfdac7fd23685b3f1e37	a61b878c2b563f289de2109fa0f42144
8a6f1a01e4b0d9e272126a8646a72088	d45cf5e6b7af0cee99b37f15b13360ed
8b0ee5a501cef4a5699fd3b2d4549e8f	12e7b1918420daf69b976a5949f9ba85
8b0ee5a501cef4a5699fd3b2d4549e8f	26a40a3dc89f8b78c61fa31d1137482c
8b427a493fc39574fc801404bc032a2f	ca69aebb5919e75661d929c1fbd39582
8bc31f7cc79c177ab7286dda04e2d1e5	a72c5a8b761c2fc1097f162eeda5d5db
8c69497eba819ee79a964a0d790368fb	d5cd210a82be3dd1a7879b83ba5657c0
8ce896355a45f5b9959eb676b8b5580c	7126a50ce66fe18b84a7bfb3defea15f
8d7a18d54e82fcfb7a11566ce94b9109	2a6b51056784227b35e412c444f54359
8e11b2f987a99ed900a44aa1aa8bd3d0	abefb7041d2488eadeedba9a0829b753
8e62fc75d9d0977d0be4771df05b3c2f	64896cd59778f32b1c61561a21af6598
8e62fc75d9d0977d0be4771df05b3c2f	dae84dc2587a374c667d0ba291f33481
8edf4531385941dfc85e3f3d3e32d24f	372ca4be7841a47ba693d4de7d220981
8edf4531385941dfc85e3f3d3e32d24f	9418ebabb93c5c1f47a05666913ec6e4
8edf4531385941dfc85e3f3d3e32d24f	c8ee19d8e2f21851dc16db65d7b138bc
8edfa58b1aedb58629b80e5be2b2bd92	7e2e7fa5ce040664bf7aaaef1cebd897
8edfa58b1aedb58629b80e5be2b2bd92	a72c5a8b761c2fc1097f162eeda5d5db
8f1f10cb698cb995fd69a671af6ecd58	c9a70f42ce4dcd82a99ed83a5117b890
8fda25275801e4a40df6c73078baf753	f5a56d2eb1cd18bf3059cc15519097ea
905a40c3533830252a909603c6fa1e6a	00f269da8a1eee6c08cebcc093968ee1
90d127641ffe2a600891cd2e3992685b	2a6b51056784227b35e412c444f54359
90d523ebbf276f516090656ebfccdc9f	372ca4be7841a47ba693d4de7d220981
9138c2cc0326412f2515623f4c850eb3	189f11691712600d4e1b0bdb4122e8aa
9138c2cc0326412f2515623f4c850eb3	85c434b11120b4ba2f116e89843a594e
91a337f89fe65fec1c97f52a821c1178	f861455af8364fc3fe01aef3fc597905
4bb93d90453dd63cc1957a033f7855c7	d1ee83d5951b1668e95b22446c38ba1c
91b18e22d4963b216af00e1dd43b5d05	ec9a23a8132c85ca37af85c69a2743c5
91c9ed0262dea7446a4f3a3e1cdd0698	abefb7041d2488eadeedba9a0829b753
925bd435e2718d623768dbf1bc1cfb60	85c434b11120b4ba2f116e89843a594e
925bd435e2718d623768dbf1bc1cfb60	f8ead2514f0df3c6e8ec84b992dd6e44
935b48a84528c4280ec208ce529deea0	a7fe0b5f5ae6fbfa811d754074e03d95
942c9f2520684c22eb6216a92b711f9e	43bcb284a3d1a0eea2c7923d45b7f14e
942c9f2520684c22eb6216a92b711f9e	939fec794a3b41bc213c4df0c66c96f5
942c9f2520684c22eb6216a92b711f9e	dae84dc2587a374c667d0ba291f33481
947ce14614263eab49f780d68555aef8	a7fe0b5f5ae6fbfa811d754074e03d95
948098e746bdf1c1045c12f042ea98c2	d8f74ab86e77455ffbd398065ee109a8
952dc6362e304f00575264e9d54d1fa6	a7fe0b5f5ae6fbfa811d754074e03d95
96682d9c9f1bed695dbf9176d3ee234c	20b7e40ecd659c47ca991e0d420a54eb
96682d9c9f1bed695dbf9176d3ee234c	53812183e083ed8a87818371d6b3dbfb
96682d9c9f1bed695dbf9176d3ee234c	568177b2430c48380b6d8dab67dbe98c
96682d9c9f1bed695dbf9176d3ee234c	c150d400f383afb8e8427813549a82d3
96682d9c9f1bed695dbf9176d3ee234c	c3b4e4db5f94fac6979eb07371836e81
96682d9c9f1bed695dbf9176d3ee234c	eb2330cf8b87aa13aad89f32d6cfda18
97ee29f216391d19f8769f79a1218a71	d5cd210a82be3dd1a7879b83ba5657c0
988d10abb9f42e7053450af19ad64c7f	85c434b11120b4ba2f116e89843a594e
990813672e87b667add44c712bb28d3d	d8f60019c8e6cdbb84839791fd989d81
99bd5eff92fc3ba728a9da5aa1971488	084c45f4c0bf86930df25ae1c59b3fe6
9a322166803a48932356586f05ef83c7	6d5c464f0c139d97e715c51b43983695
9ab8f911c74597493400602dc4d2b412	2a6b51056784227b35e412c444f54359
9b1088b616414d0dc515ab1f2b4922f1	c8ee19d8e2f21851dc16db65d7b138bc
9bc2ca9505a273b06aa0b285061cd1de	f68790d8b2f82aad75f0c27be554ee48
9bc2ca9505a273b06aa0b285061cd1de	f861455af8364fc3fe01aef3fc597905
9cf73d0300eea453f17c6faaeb871c55	f68790d8b2f82aad75f0c27be554ee48
9d3ac6904ce73645c6234803cd7e47ca	6b09e6ae26a0d03456b17df4c0964a2f
9d969d25c9f506c5518bb090ad5f8266	d8f74ab86e77455ffbd398065ee109a8
9db9bc745a7568b51b3a968d215ddad6	dae84dc2587a374c667d0ba291f33481
9e84832a15f2698f67079a3224c2b6fb	a7fe0b5f5ae6fbfa811d754074e03d95
9f19396638dd8111f2cee938fdf4e455	2a6b51056784227b35e412c444f54359
a332f1280622f9628fccd1b7aac7370a	d5cd210a82be3dd1a7879b83ba5657c0
a3f5542dc915b94a5e10dab658bb0959	8368e0fd31972c67de1117fb0fe12268
a4902fb3d5151e823c74dfd51551b4b0	372ca4be7841a47ba693d4de7d220981
a4977b96c7e5084fcce21a0d07b045f8	64896cd59778f32b1c61561a21af6598
a4cbfb212102da21b82d94be555ac3ec	00f269da8a1eee6c08cebcc093968ee1
a538bfe6fe150a92a72d78f89733dbd0	663ea93736c204faee5f6c339203be3e
a61b878c2b563f289de2109fa0f42144	a61b878c2b563f289de2109fa0f42144
a650d82df8ca65bb69a45242ab66b399	dae84dc2587a374c667d0ba291f33481
a716390764a4896d99837e99f9e009c9	488af8bdc554488b6c8854fae6ae8610
a716390764a4896d99837e99f9e009c9	dae84dc2587a374c667d0ba291f33481
a7a9c1b4e7f10bd1fdf77aff255154f7	42c7a1c1e7836f74ced153a27d98cef0
a7f9797e4cd716e1516f9d4845b0e1e2	1fad423d9d1f48b7bd6d31c8d5cb17ed
a7f9797e4cd716e1516f9d4845b0e1e2	8224efe45b1d8a1ebc0b9fb0a5405ac6
a825b2b87f3b61c9660b81f340f6e519	ec9a23a8132c85ca37af85c69a2743c5
a8d9eeed285f1d47836a5546a280a256	6b09e6ae26a0d03456b17df4c0964a2f
a8d9eeed285f1d47836a5546a280a256	ca69aebb5919e75661d929c1fbd39582
aa0d528ba11ea1485d466dfe1ea40819	3af7c6d148d216f13f66669acb8d5c59
aa0d528ba11ea1485d466dfe1ea40819	c150d400f383afb8e8427813549a82d3
aa0d528ba11ea1485d466dfe1ea40819	d5cd210a82be3dd1a7879b83ba5657c0
aa86b6fc103fc757e14f03afe6eb0c0a	f8549f73852c778caa3e9c09558739f2
abbf8e3e3c3e78be8bd886484c1283c1	2a6b51056784227b35e412c444f54359
abd7ab19ff758cf4c1a2667e5bbac444	633f06bd0bd191373d667af54af0939b
ac03fad3be179a237521ec4ef2620fb0	0a85beacde1a467e23452f40b4710030
ac03fad3be179a237521ec4ef2620fb0	a72c5a8b761c2fc1097f162eeda5d5db
ac94d15f46f10707a39c4bc513cd9f98	06e5f3d0d817c436d351a9cf1bf94dfa
ad01952b3c254c8ebefaf6f73ae62f7d	0dcd062f5beffeaae2efae21ef9f3755
ad01952b3c254c8ebefaf6f73ae62f7d	b6aaab867e3c1c7bfe215d7db747e5d9
ad62209fb63910acf40280cea3647ec5	a7fe0b5f5ae6fbfa811d754074e03d95
ade72e999b4e78925b18cf48d1faafa4	e471494f42d963b13f025c0636c43763
aed85c73079b54830cd50a75c0958a90	633f06bd0bd191373d667af54af0939b
aed85c73079b54830cd50a75c0958a90	a7fe0b5f5ae6fbfa811d754074e03d95
b01fbaf98cfbc1b72e8bca0b2e48769c	00f269da8a1eee6c08cebcc093968ee1
b0ce1e93de9839d07dab8d268ca23728	7126a50ce66fe18b84a7bfb3defea15f
b14814d0ee12ffadc8f09ab9c604a9d0	939fec794a3b41bc213c4df0c66c96f5
b1bdad87bd3c4ac2c22473846d301a9e	3af7c6d148d216f13f66669acb8d5c59
b1bdad87bd3c4ac2c22473846d301a9e	85c434b11120b4ba2f116e89843a594e
b1d465aaf3ccf8701684211b1623adf2	dae84dc2587a374c667d0ba291f33481
b3ffff8517114caf70b9e70734dbaf6f	dae84dc2587a374c667d0ba291f33481
b570e354b7ebc40e20029fcc7a15e5a7	372ca4be7841a47ba693d4de7d220981
b570e354b7ebc40e20029fcc7a15e5a7	8224efe45b1d8a1ebc0b9fb0a5405ac6
b570e354b7ebc40e20029fcc7a15e5a7	9e829f734a90920dd15d3b93134ee270
b5d9c5289fe97968a5634b3e138bf9e2	f8ead2514f0df3c6e8ec84b992dd6e44
b5f7b25b0154c34540eea8965f90984d	a7ea7b6c1894204987ce4694c1febe03
b6da055500e3d92698575a3cfc74906c	63a722e7e0aa4866721305fab1342530
b885447285ece8226facd896c04cdba2	8640cd270510da320a9dd71429b95531
b885447285ece8226facd896c04cdba2	a2cc2bc245b90654e721d7040c028647
b89e91ccf14bfd7f485dd7be7d789b0a	9e829f734a90920dd15d3b93134ee270
b96a3cb81197e8308c87f6296174fe3e	0aa506a505f1115202f993ee4d650480
baa9d4eef21c7b89f42720313b5812d4	5e45d87cab8e0b30fba4603b4821bfcd
bb4cc149e8027369e71eb1bb36cd98e0	e1baa5fa38e1e6c824f2011f89475f03
bbb668ff900efa57d936e726a09e4fe8	dae84dc2587a374c667d0ba291f33481
bbc155fb2b111bf61c4f5ff892915e6b	be95780f2b4fba1a76846b716e69ed6d
bbce8e45250a239a252752fac7137e00	bbce8e45250a239a252752fac7137e00
bd4184ee062e4982b878b6b188793f5b	abefb7041d2488eadeedba9a0829b753
be20385e18333edb329d4574f364a1f0	553a00f0c40ce1b1107f833da69988e4
bfc9ace5d2a11fae56d038d68c601f00	00da417154f2da39e79c9dcf4d7502fa
c05d504b806ad065c9b548c0cb1334cd	568177b2430c48380b6d8dab67dbe98c
c127f32dc042184d12b8c1433a77e8c4	ec9a23a8132c85ca37af85c69a2743c5
c1923ca7992dc6e79d28331abbb64e72	cc4617b9ce3c2eee5d1e566eb2fbb1f6
c2855b6617a1b08fed3824564e15a653	060fd8422f03df6eca94da7605b3a9cd
c3490492512b7fe65cdb0c7305044675	dcda9434b422f9aa793f0a8874922306
c4678a2e0eef323aeb196670f2bc8a6e	633f06bd0bd191373d667af54af0939b
c4c7cb77b45a448aa3ca63082671ad97	00f269da8a1eee6c08cebcc093968ee1
c4ddbffb73c1c34d20bd5b3f425ce4b1	dae84dc2587a374c667d0ba291f33481
c4f0f5cedeffc6265ec3220ab594d56b	8640cd270510da320a9dd71429b95531
c5dc33e23743fb951b3fe7f1f477b794	8368e0fd31972c67de1117fb0fe12268
c5f022ef2f3211dc1e3b8062ffe764f0	00f269da8a1eee6c08cebcc093968ee1
c74b5aa120021cbe18dcddd70d8622da	0a85beacde1a467e23452f40b4710030
c883319a1db14bc28eff8088c5eba10e	2a6b51056784227b35e412c444f54359
ca5a010309ffb20190558ec20d97e5b2	d5cd210a82be3dd1a7879b83ba5657c0
cafe9e68e8f90b3e1328da8858695b31	ca69aebb5919e75661d929c1fbd39582
cafe9e68e8f90b3e1328da8858695b31	d2a4c05671f768ba487ad365d2a0fb6e
cd9483c1733b17f57d11a77c9404893c	9e829f734a90920dd15d3b93134ee270
cddf835bea180bd14234a825be7a7a82	d8f60019c8e6cdbb84839791fd989d81
ce2caf05154395724e4436f042b8fa53	00f269da8a1eee6c08cebcc093968ee1
ce2caf05154395724e4436f042b8fa53	d8f74ab86e77455ffbd398065ee109a8
cf4ee20655dd3f8f0a553c73ffe3f72a	2a6b51056784227b35e412c444f54359
d05a0e65818a69cc689b38c0c0007834	abefb7041d2488eadeedba9a0829b753
d0a1fd0467dc892f0dc27711637c864e	2a6b51056784227b35e412c444f54359
d1fb4e47d8421364f49199ee395ad1d3	cc4617b9ce3c2eee5d1e566eb2fbb1f6
d2ff1e521585a91a94fb22752dd0ab45	0a85beacde1a467e23452f40b4710030
d39d7a2bb6d430fd238a6aedc7f0cee2	e471494f42d963b13f025c0636c43763
d3e98095eeccaa253050d67210ef02bb	dd50d5dcc02ea12c31e0ff495891dc22
d3ed8223151e14b936436c336a4c7278	d45cf5e6b7af0cee99b37f15b13360ed
d433b7c1ce696b94a8d8f72de6cfbeaa	d5cd210a82be3dd1a7879b83ba5657c0
d449a9b2eed8b0556dc7be9cda36b67b	ca69aebb5919e75661d929c1fbd39582
d6de9c99f5cfa46352b2bc0be5c98c41	2a6b51056784227b35e412c444f54359
d730e65d54d6c0479561d25724afd813	ca69aebb5919e75661d929c1fbd39582
d73310b95e8b4dece44e2a55dd1274e6	c9a70f42ce4dcd82a99ed83a5117b890
d857ab11d383a7e4d4239a54cbf2a63d	084c45f4c0bf86930df25ae1c59b3fe6
d857ab11d383a7e4d4239a54cbf2a63d	9afc751ca7f2d91d23c453b32fd21864
d9ab6b54c3bd5b212e8dc3a14e7699ef	ff3bed6eb88bb82b3a77ddaf50933689
da2110633f62b16a571c40318e4e4c1c	53812183e083ed8a87818371d6b3dbfb
da867941c8bacf9be8e59bc13d765f92	06e5f3d0d817c436d351a9cf1bf94dfa
db38e12f9903b156f9dc91fce2ef3919	2a6b51056784227b35e412c444f54359
db46d9a37b31baa64cb51604a2e4939a	cc4617b9ce3c2eee5d1e566eb2fbb1f6
dcabc7299e2b9ed5b05c33273e5fdd19	f68790d8b2f82aad75f0c27be554ee48
dcff9a127428ffb03fc02fdf6cc39575	42c7a1c1e7836f74ced153a27d98cef0
dd18fa7a5052f2bce8ff7cb4a30903ea	85c434b11120b4ba2f116e89843a594e
dddb04bc0d058486d0ef0212c6ea0682	189f11691712600d4e1b0bdb4122e8aa
de12bbf91bc797df25ab4ae9cee1946b	6b09e6ae26a0d03456b17df4c0964a2f
deaccc41a952e269107cc9a507dfa131	8640cd270510da320a9dd71429b95531
dfdef9b5190f331de20fe029babf032e	dae84dc2587a374c667d0ba291f33481
e08383c479d96a8a762e23a99fd8bf84	d5cd210a82be3dd1a7879b83ba5657c0
e0c2b0cc2e71294cd86916807fef62cb	d2a4c05671f768ba487ad365d2a0fb6e
e0de9c10bbf73520385ea5dcbdf62073	63a722e7e0aa4866721305fab1342530
e0de9c10bbf73520385ea5dcbdf62073	ca69aebb5919e75661d929c1fbd39582
e0f39406f0e15487dd9d3997b2f5ca61	20cf9df7281c50060aaf023e04fd5082
e1db3add02ca4c1af33edc5a970a3bdc	d2a4c05671f768ba487ad365d2a0fb6e
e271e871e304f59e62a263ffe574ea2d	c150d400f383afb8e8427813549a82d3
e29ef4beb480eab906ffa7c05aeec23d	dae84dc2587a374c667d0ba291f33481
e3f0bf612190af6c3fad41214115e004	ca69aebb5919e75661d929c1fbd39582
e4b3296f8a9e2a378eb3eb9576b91a37	6b09e6ae26a0d03456b17df4c0964a2f
e61e30572fd58669ae9ea410774e0eb6	00f269da8a1eee6c08cebcc093968ee1
e62a773154e1179b0cc8c5592207cb10	ca69aebb5919e75661d929c1fbd39582
e64b94f14765cee7e05b4bec8f5fee31	ec9a23a8132c85ca37af85c69a2743c5
e64d38b05d197d60009a43588b2e4583	372ca4be7841a47ba693d4de7d220981
e67e51d5f41cfc9162ef7fd977d1f9f5	189f11691712600d4e1b0bdb4122e8aa
e74a88c71835c14d92d583a1ed87cc6c	6d5c464f0c139d97e715c51b43983695
e872b77ff7ac24acc5fa373ebe9bb492	e872b77ff7ac24acc5fa373ebe9bb492
e8afde257f8a2cbbd39d866ddfc06103	00f269da8a1eee6c08cebcc093968ee1
eb2c788da4f36fba18b85ae75aff0344	0a85beacde1a467e23452f40b4710030
ed24ff8971b1fa43a1efbb386618ce35	dae84dc2587a374c667d0ba291f33481
ee69e7d19f11ca58843ec2e9e77ddb38	ca69aebb5919e75661d929c1fbd39582
eeaeec364c925e0c821660c7a953546e	63a722e7e0aa4866721305fab1342530
ef6369d9794dbe861a56100e92a3c71d	d5cd210a82be3dd1a7879b83ba5657c0
f042da2a954a1521114551a6f9e22c75	4c90356614158305d8527b80886d2c1e
f042da2a954a1521114551a6f9e22c75	568177b2430c48380b6d8dab67dbe98c
f042da2a954a1521114551a6f9e22c75	d2a4c05671f768ba487ad365d2a0fb6e
f07c3eef5b7758026d45a12c7e2f6134	53812183e083ed8a87818371d6b3dbfb
f07c3eef5b7758026d45a12c7e2f6134	c3b4e4db5f94fac6979eb07371836e81
f0c051b57055b052a3b7da1608f3039e	eb2330cf8b87aa13aad89f32d6cfda18
f0e1f32b93f622ea3ddbf6b55b439812	dae84dc2587a374c667d0ba291f33481
f29d276fd930f1ad7687ed7e22929b64	2a6b51056784227b35e412c444f54359
f29d276fd930f1ad7687ed7e22929b64	d2a4c05671f768ba487ad365d2a0fb6e
f37ab058561fb6d233b9c2a0b080d4d1	dae84dc2587a374c667d0ba291f33481
f4219e8fec02ce146754a5be8a85f246	189f11691712600d4e1b0bdb4122e8aa
f4f870098db58eeae93742dd2bcaf2b2	0a85beacde1a467e23452f40b4710030
f60ab90d94b9cafe6b32f6a93ee8fcda	1fad423d9d1f48b7bd6d31c8d5cb17ed
f644bd92037985f8eb20311bc6d5ed94	00f269da8a1eee6c08cebcc093968ee1
f8e7112b86fcd9210dfaf32c00d6d375	0e33f8fbbb12367a6e8159a3b096898a
f953fa7b33e7b6503f4380895bbe41c8	8224efe45b1d8a1ebc0b9fb0a5405ac6
fa03eb688ad8aa1db593d33dabd89bad	abefb7041d2488eadeedba9a0829b753
faabbecd319372311ed0781d17b641d1	a72c5a8b761c2fc1097f162eeda5d5db
fb28e62c0e801a787d55d97615e89771	f10fa26efffb6c69534e7b0f7890272d
fb47f889f2c7c4fee1553d0f817b8aaa	85c434b11120b4ba2f116e89843a594e
fb47f889f2c7c4fee1553d0f817b8aaa	b6aaab867e3c1c7bfe215d7db747e5d9
fb8be6409408481ad69166324bdade9c	0a85beacde1a467e23452f40b4710030
fcd1c1b547d03e760d1defa4d2b98783	6b09e6ae26a0d03456b17df4c0964a2f
fd85bfffd5a0667738f6110281b25db8	00da417154f2da39e79c9dcf4d7502fa
fdc90583bd7a58b91384dea3d1659cde	abefb7041d2488eadeedba9a0829b753
fe228019addf1d561d0123caae8d1e52	abefb7041d2488eadeedba9a0829b753
fe5b73c2c2cd2d9278c3835c791289b6	a72c5a8b761c2fc1097f162eeda5d5db
fe5b73c2c2cd2d9278c3835c791289b6	d1ee83d5951b1668e95b22446c38ba1c
ff578d3db4dc3311b3098c8365d54e6b	189f11691712600d4e1b0bdb4122e8aa
ff578d3db4dc3311b3098c8365d54e6b	a7fe0b5f5ae6fbfa811d754074e03d95
ff5b48d38ce7d0c47c57555d4783a118	d2a4c05671f768ba487ad365d2a0fb6e
ffa7450fd138573d8ae665134bccd02c	0a85beacde1a467e23452f40b4710030
fdcf3cdc04f367257c92382e032b6293	d0f1ffdb2d3a20a41f9c0f10df3b9386
bbddc022ee323e0a2b2d8c67e5cd321f	d0f1ffdb2d3a20a41f9c0f10df3b9386
4bb93d90453dd63cc1957a033f7855c7	d0f1ffdb2d3a20a41f9c0f10df3b9386
94ca28ea8d99549c2280bcc93f98c853	73d6ec35ad0e4ef8f213ba89d8bfd7d7
24ff2b4548c6bc357d9d9ab47882661e	73d6ec35ad0e4ef8f213ba89d8bfd7d7
fd85bfffd5a0667738f6110281b25db8	441306dd21b61d9a52e04b9e177cc9b5
1cdd53cece78d6e8dffcf664fa3d1be2	441306dd21b61d9a52e04b9e177cc9b5
6d89517dbd1a634b097f81f5bdbb07a2	441306dd21b61d9a52e04b9e177cc9b5
eb3bfb5a3ccdd4483aabc307ae236066	441306dd21b61d9a52e04b9e177cc9b5
0ab20b5ad4d15b445ed94fa4eebb18d8	441306dd21b61d9a52e04b9e177cc9b5
33f03dd57f667d41ac77c6baec352a81	441306dd21b61d9a52e04b9e177cc9b5
399033f75fcf47d6736c9c5209222ab8	441306dd21b61d9a52e04b9e177cc9b5
d9bc1db8c13da3a131d853237e1f05b2	441306dd21b61d9a52e04b9e177cc9b5
1197a69404ee9475146f3d631de12bde	441306dd21b61d9a52e04b9e177cc9b5
12e93f5fab5f7d16ef37711ef264d282	441306dd21b61d9a52e04b9e177cc9b5
fdcbfded0aaf369d936a70324b39c978	13afebb96e2d2d27345bd3b1fefc4db0
52ee4c6902f6ead006b0fb2f3e2d7771	13afebb96e2d2d27345bd3b1fefc4db0
96682d9c9f1bed695dbf9176d3ee234c	f3603438cf79ee848cb2f5e4a5884663
1056b63fdc3c5015cc4591aa9989c14f	f3603438cf79ee848cb2f5e4a5884663
754230e2c158107a2e93193c829e9e59	3c61b014201d6f62468d72d0363f7725
1ac0c8e8c04cf2d6f02fdb8292e74588	3c61b014201d6f62468d72d0363f7725
f042da2a954a1521114551a6f9e22c75	a71ac13634cd0b6d26e52d11c76f0a63
4fab532a185610bb854e0946f4def6a4	a71ac13634cd0b6d26e52d11c76f0a63
a29c1c4f0a97173007be3b737e8febcc	a71ac13634cd0b6d26e52d11c76f0a63
96048e254d2e02ba26f53edd271d3f88	8d821ce4aedb7300e067cfa9eb7f1eee
da29e297c23e7868f1d50ec5a6a4359b	8d821ce4aedb7300e067cfa9eb7f1eee
e6fd7b62a39c109109d33fcd3b5e129d	8d821ce4aedb7300e067cfa9eb7f1eee
e25ee917084bdbdc8506b56abef0f351	8d821ce4aedb7300e067cfa9eb7f1eee
6b7cf117ecf0fea745c4c375c1480cb5	8d821ce4aedb7300e067cfa9eb7f1eee
99bd5eff92fc3ba728a9da5aa1971488	8d821ce4aedb7300e067cfa9eb7f1eee
754230e2c158107a2e93193c829e9e59	fce1fb772d7bd71211bb915625ac11af
754230e2c158107a2e93193c829e9e59	95f89582ba9dcfbed475ebb3c06162db
96682d9c9f1bed695dbf9176d3ee234c	fce1fb772d7bd71211bb915625ac11af
c2275e8ac71d308946a63958bc7603a1	95f89582ba9dcfbed475ebb3c06162db
dde3e0b0cc344a7b072bbab8c429f4ff	9f1a399c301132b273f595b1cfc5e99d
3bcbddf6c114327fc72ea06bcb02f9ef	9f1a399c301132b273f595b1cfc5e99d
b785a5ffad5e7e36ccac25c51d5d8908	23fcfcbd4fa686b213960a04f49856f4
2aae4f711c09481c8353003202e05359	23fcfcbd4fa686b213960a04f49856f4
4bb93d90453dd63cc1957a033f7855c7	54bf7e97edddf051b2a98b21b6d47e6a
f042da2a954a1521114551a6f9e22c75	bb378a3687cc64953bf36ccea6eb5a27
abd7ab19ff758cf4c1a2667e5bbac444	46ffa374af00ed2b76c1cfaa98b76e90
63c0a328ae2bee49789212822f79b83f	46ffa374af00ed2b76c1cfaa98b76e90
28bc31b338dbd482802b77ed1fd82a50	46ffa374af00ed2b76c1cfaa98b76e90
83d15841023cff02eafedb1c87df9b11	46ffa374af00ed2b76c1cfaa98b76e90
d9bc1db8c13da3a131d853237e1f05b2	46ffa374af00ed2b76c1cfaa98b76e90
99bd5eff92fc3ba728a9da5aa1971488	46ffa374af00ed2b76c1cfaa98b76e90
f03bde11d261f185cbacfa32c1c6538c	46ffa374af00ed2b76c1cfaa98b76e90
f6540bc63be4c0cb21811353c0d24f69	46ffa374af00ed2b76c1cfaa98b76e90
e4f0ad5ef0ac3037084d8a5e3ca1cabc	46ffa374af00ed2b76c1cfaa98b76e90
ea16d031090828264793e860a00cc995	46ffa374af00ed2b76c1cfaa98b76e90
5eed658c4b7b68a0ecc49205b68d54e7	46ffa374af00ed2b76c1cfaa98b76e90
a0fb30950d2a150c1d2624716f216316	0cd1c230352e99227f43acc46129d6b4
4ad6c928711328d1cf0167bc87079a14	0cd1c230352e99227f43acc46129d6b4
96e3cdb363fe6df2723be5b994ad117a	0cd1c230352e99227f43acc46129d6b4
c8d551145807972d194691247e7102a2	0cd1c230352e99227f43acc46129d6b4
96682d9c9f1bed695dbf9176d3ee234c	6f14a4e8ecdf87e02d77cec09b6c98b9
f0c051b57055b052a3b7da1608f3039e	6f14a4e8ecdf87e02d77cec09b6c98b9
3d01ff8c75214314c4ca768c30e6807b	808e3291422cea1b35c76af1b5ba5326
99bd5eff92fc3ba728a9da5aa1971488	808e3291422cea1b35c76af1b5ba5326
2a024edafb06c7882e2e1f7b57f2f951	808e3291422cea1b35c76af1b5ba5326
45b568ce63ea724c415677711b4328a7	20970f44b43a10d7282a77eda20866e2
10d91715ea91101cfe0767c812da8151	20970f44b43a10d7282a77eda20866e2
99bd5eff92fc3ba728a9da5aa1971488	9feb9a9930d633ef18e1dae581b65327
c238980432ab6442df9b2c6698c43e47	9feb9a9930d633ef18e1dae581b65327
145bd9cf987b6f96fa6f3b3b326303c9	9feb9a9930d633ef18e1dae581b65327
39a25b9c88ce401ca54fd7479d1c8b73	8342e65069254a6fd6d2bbc87aff8192
8cadf0ad04644ce2947bf3aa2817816e	8342e65069254a6fd6d2bbc87aff8192
85fac49d29a31f1f9a8a18d6b04b9fc9	8342e65069254a6fd6d2bbc87aff8192
b81ee269be538a500ed057b3222c86a2	8342e65069254a6fd6d2bbc87aff8192
cf71a88972b5e06d8913cf53c916e6e4	8342e65069254a6fd6d2bbc87aff8192
5518086aebc9159ba7424be0073ce5c9	8342e65069254a6fd6d2bbc87aff8192
60f28c7011b5e32d220cbaa0e563291b	8342e65069254a6fd6d2bbc87aff8192
6eaeee13a99072e69bab1f707b79c56a	8342e65069254a6fd6d2bbc87aff8192
2c4e2c9948ddac6145e529c2ae7296da	8342e65069254a6fd6d2bbc87aff8192
c9af1c425ca093648e919c2e471df3bd	8342e65069254a6fd6d2bbc87aff8192
0291e38d9a3d398052be0ca52a7b1592	8342e65069254a6fd6d2bbc87aff8192
8852173e80d762d62f0bcb379d82ebdb	8342e65069254a6fd6d2bbc87aff8192
000f49c98c428aff4734497823d04f45	8342e65069254a6fd6d2bbc87aff8192
dea293bdffcfb292b244b6fe92d246dc	8342e65069254a6fd6d2bbc87aff8192
1cdd53cece78d6e8dffcf664fa3d1be2	8342e65069254a6fd6d2bbc87aff8192
d0a1fd0467dc892f0dc27711637c864e	8342e65069254a6fd6d2bbc87aff8192
302ebe0389198972c223f4b72894780a	320951dccf4030808c979375af8356b6
ac62ad2816456aa712809bf01327add1	320951dccf4030808c979375af8356b6
470f3f69a2327481d26309dc65656f44	320951dccf4030808c979375af8356b6
e254616b4a5bd5aaa54f90a3985ed184	320951dccf4030808c979375af8356b6
3c5c578b7cf5cc0d23c1730d1d51436a	320951dccf4030808c979375af8356b6
eaeaed2d9f3137518a5c8c7e6733214f	320951dccf4030808c979375af8356b6
8ccd65d7f0f028405867991ae3eaeb56	320951dccf4030808c979375af8356b6
d0a1fd0467dc892f0dc27711637c864e	320951dccf4030808c979375af8356b6
5f992768f7bb9592bed35b07197c87d0	320951dccf4030808c979375af8356b6
b1bdad87bd3c4ac2c22473846d301a9e	320951dccf4030808c979375af8356b6
781acc7e58c9a746d58f6e65ab1e90c4	7712d7dceef5a521b4a554c431752979
e5a674a93987de4a52230105907fffe9	7712d7dceef5a521b4a554c431752979
a2459c5c8a50215716247769c3dea40b	7712d7dceef5a521b4a554c431752979
e285e4ecb358b92237298f67526beff7	7712d7dceef5a521b4a554c431752979
dfdef9b5190f331de20fe029babf032e	7712d7dceef5a521b4a554c431752979
d832b654664d104f0fbb9b6674a09a11	7712d7dceef5a521b4a554c431752979
2aeb128c6d3eb7e79acb393b50e1cf7b	7712d7dceef5a521b4a554c431752979
213c449bd4bcfcdb6bffecf55b2c30b4	7712d7dceef5a521b4a554c431752979
4ea353ae22a1c0d26327638f600aeac8	7712d7dceef5a521b4a554c431752979
8b0ee5a501cef4a5699fd3b2d4549e8f	6118dc6a9a96e892fa5bbaac3ccb6d99
66244bb43939f81c100f03922cdc3439	6118dc6a9a96e892fa5bbaac3ccb6d99
7df8865bbec157552b8a579e0ed9bfe3	6118dc6a9a96e892fa5bbaac3ccb6d99
be20385e18333edb329d4574f364a1f0	6118dc6a9a96e892fa5bbaac3ccb6d99
8edfa58b1aedb58629b80e5be2b2bd92	9c697f7def422e3f6f885d3ec9741603
da2110633f62b16a571c40318e4e4c1c	9c697f7def422e3f6f885d3ec9741603
5b709b96ee02a30be5eee558e3058245	b1e4aa22275a6a4b3213b44fc342f9fe
754230e2c158107a2e93193c829e9e59	b1e4aa22275a6a4b3213b44fc342f9fe
96682d9c9f1bed695dbf9176d3ee234c	31c3824b57ad0919df18a79978c701e9
2df8905eae6823023de6604dc5346c29	31c3824b57ad0919df18a79978c701e9
\.


--
-- Data for Name: bands_generes; Type: TABLE DATA; Schema: music; Owner: postgres
--

COPY music.bands_generes (id_band, id_genere) FROM stdin;
0020f19414b5f2874a0bfacd9d511b84	cb6ef856481bc776bba38fbf15b8b3fb
006fc2724417174310cf06d2672e34d2	17b8dff9566f6c98062ad5811c762f44
02d44fbbe1bfacd6eaa9b20299b1cb78	7fa69773873856d74f68a6824ca4b691
02d44fbbe1bfacd6eaa9b20299b1cb78	deb8040131c3f6a3caf6a616b34ac482
058fcf8b126253956deb3ce672d107a7	6de7f9aa9c912bf8c81a9ce2bfc062bd
058fcf8b126253956deb3ce672d107a7	7a3808eef413b514776a7202fd2cb94f
059792b70fc0686fb296e7fcae0bda50	17b8dff9566f6c98062ad5811c762f44
0640cfbf1d269b69c535ea4e288dfd96	97a6395e2906e8f41d27e53a40aebae4
065b56757c6f6a0fba7ab0c64e4c1ae1	17b8dff9566f6c98062ad5811c762f44
06efe152a554665e02b8dc4f620bf3f1	585f02a68092351a078fc43a21a56564
06efe152a554665e02b8dc4f620bf3f1	a29864963573d7bb061691ff823b97dd
076365679712e4206301117486c3d0ec	17b8dff9566f6c98062ad5811c762f44
076365679712e4206301117486c3d0ec	a29864963573d7bb061691ff823b97dd
076365679712e4206301117486c3d0ec	d5a9c37bc91d6d5d55a3c2e38c3bf97d
0780d2d1dbd538fec3cdd8699b08ea02	60e1fa5bfa060b5fff1db1ca1bae4f99
0780d2d1dbd538fec3cdd8699b08ea02	885ba57d521cd859bacf6f76fb37ef7c
0780d2d1dbd538fec3cdd8699b08ea02	a178914dea39e23c117e164b05b43995
0780d2d1dbd538fec3cdd8699b08ea02	ed8e37bad13d76c6dbeb58152440b41e
0844ad55f17011abed4a5208a3a05b74	10a17b42501166d3bf8fbdff7e1d52b6
0844ad55f17011abed4a5208a3a05b74	17b8dff9566f6c98062ad5811c762f44
0903a7e60f0eb20fdc8cc0b8dbd45526	4144b216bf706803a5f17d7d0a9cf4a3
095849fbdc267416abc6ddb48be311d7	7fa69773873856d74f68a6824ca4b691
095849fbdc267416abc6ddb48be311d7	caac3244eefed8cffee878acae427e28
09d8e20a5368ce1e5c421a04cb566434	a379c6c3bf4b1a401ce748b34729389a
0a267617c0b5b4d53e43a7d4e4c522ad	10a17b42501166d3bf8fbdff7e1d52b6
0a267617c0b5b4d53e43a7d4e4c522ad	17b8dff9566f6c98062ad5811c762f44
0a267617c0b5b4d53e43a7d4e4c522ad	1d67aeafcd3b898e05a75da0fdc01365
0a267617c0b5b4d53e43a7d4e4c522ad	a68d5b72c2f98613f511337a59312f78
0a267617c0b5b4d53e43a7d4e4c522ad	ea9565886c02dbdc4892412537e607d7
0a56095b73dcbd2a76bb9d4831881cb3	ea9565886c02dbdc4892412537e607d7
0a7ba3f35a9750ff956dca1d548dad12	01864d382accf1cdb077e42032b16340
0a97b893b92a7df612eadfe97589f242	eaa57a9b4248ce3968e718895e1c2f04
0af74c036db52f48ad6cbfef6fee2999	04ae76937270105919847d05aee582b4
0af74c036db52f48ad6cbfef6fee2999	a29864963573d7bb061691ff823b97dd
0af74c036db52f48ad6cbfef6fee2999	f41da0c65a8fa3690e6a6877e7112afb
0b0d1c3752576d666c14774b8233889f	01864d382accf1cdb077e42032b16340
0b6e98d660e2901c33333347da37ad36	04ae76937270105919847d05aee582b4
0cdf051c93865faa15cbc5cd3d2b69fb	a29864963573d7bb061691ff823b97dd
0e2ea6aa669710389cf4d6e2ddf408c4	a68d5b72c2f98613f511337a59312f78
0fbddeb130361265f1ba6f86b00f0968	10a17b42501166d3bf8fbdff7e1d52b6
1056b63fdc3c5015cc4591aa9989c14f	a29864963573d7bb061691ff823b97dd
108c58fc39b79afc55fac7d9edf4aa2a	01864d382accf1cdb077e42032b16340
10d91715ea91101cfe0767c812da8151	17b8dff9566f6c98062ad5811c762f44
10d91715ea91101cfe0767c812da8151	a29864963573d7bb061691ff823b97dd
1104831a0d0fe7d2a6a4198c781e0e0d	a29864963573d7bb061691ff823b97dd
11635778f116ce6922f6068638a39028	04ae76937270105919847d05aee582b4
11635778f116ce6922f6068638a39028	6fb9bf02fc5d663c1de8c117382bed0b
11635778f116ce6922f6068638a39028	f0095594f17b3793be8291117582f96b
11d396b078f0ae37570c8ef0f45937ad	9ba0204bc48d4b8721344dd83b832afe
11f8d9ec8f6803ea61733840f13bc246	7fa69773873856d74f68a6824ca4b691
1209f43dbecaba22f3514bf40135f991	1e612d6c48bc9652afeb616536fced51
121189969c46f49b8249633c2d5a7bfa	a29864963573d7bb061691ff823b97dd
13caf3d14133dfb51067264d857eaf70	1c800aa97116d9afd83204d65d50199a
14ab730fe0172d780da6d9e5d432c129	a29864963573d7bb061691ff823b97dd
1734b04cf734cb291d97c135d74b4b87	2df929d9b6150c082888b66e8129ee3f
1734b04cf734cb291d97c135d74b4b87	7fa69773873856d74f68a6824ca4b691
187ebdf7947f4b61e0725c93227676a4	2df929d9b6150c082888b66e8129ee3f
187ebdf7947f4b61e0725c93227676a4	97a6395e2906e8f41d27e53a40aebae4
19baf8a6a25030ced87cd0ce733365a9	10a17b42501166d3bf8fbdff7e1d52b6
19baf8a6a25030ced87cd0ce733365a9	17b8dff9566f6c98062ad5811c762f44
1ac0c8e8c04cf2d6f02fdb8292e74588	2e607ef3a19cf3de029e2c5882896d33
1ac0c8e8c04cf2d6f02fdb8292e74588	a29864963573d7bb061691ff823b97dd
1bc1f7348d79a353ea4f594de9dd1392	01864d382accf1cdb077e42032b16340
1bc1f7348d79a353ea4f594de9dd1392	d5a9c37bc91d6d5d55a3c2e38c3bf97d
1c06fc6740d924cab33dce73643d84b9	eb182befdeccf17696b666b32eb5a313
1c6987adbe5ab3e4364685e8caed0f59	04ae76937270105919847d05aee582b4
1c6987adbe5ab3e4364685e8caed0f59	4fb2ada7c5440a256ed0e03c967fce74
1cdd53cece78d6e8dffcf664fa3d1be2	17b8dff9566f6c98062ad5811c762f44
1da77fa5b97c17be83cc3d0693c405cf	1c800aa97116d9afd83204d65d50199a
1e14d6b40d8e81d8d856ba66225dcbf3	a29864963573d7bb061691ff823b97dd
1e8563d294da81043c2772b36753efaf	1396a3913454b8016ddf671d02e861b1
1e8563d294da81043c2772b36753efaf	2a78330cc0de19f12ae9c7de65b9d5d5
1e8563d294da81043c2772b36753efaf	8472603ee3d6dea8e274608e9cbebb6b
1e8563d294da81043c2772b36753efaf	dcd00c11302e3b16333943340d6b4a6b
1e88302efcfc873691f0c31be4e2a388	a29864963573d7bb061691ff823b97dd
1e9413d4cc9af0ad12a6707776573ba0	7fa69773873856d74f68a6824ca4b691
1ebd63d759e9ff532d5ce63ecb818731	b86219c2df5a0d889f490f88ff22e228
2082a7d613f976e7b182a3fe80a28958	de62af4f3af4adf9e8c8791071ddafe3
2113f739f81774557041db616ee851e6	17b8dff9566f6c98062ad5811c762f44
218f2bdae8ad3bb60482b201e280ffdc	7fa69773873856d74f68a6824ca4b691
2252d763a2a4ac815b122a0176e3468f	a68d5b72c2f98613f511337a59312f78
237e378c239b44bff1e9a42ab866580c	17b8dff9566f6c98062ad5811c762f44
237e378c239b44bff1e9a42ab866580c	a68d5b72c2f98613f511337a59312f78
2414366fe63cf7017444181acacb6347	10a17b42501166d3bf8fbdff7e1d52b6
2414366fe63cf7017444181acacb6347	17b8dff9566f6c98062ad5811c762f44
2447873ddeeecaa165263091c0cbb22f	a68d5b72c2f98613f511337a59312f78
249229ca88aa4a8815315bb085cf4d61	02d3190ce0f08f32be33da6cc8ec8df8
249229ca88aa4a8815315bb085cf4d61	bb273189d856ee630d92fbc0274178bb
249789ae53c239814de8e606ff717ec9	04ae76937270105919847d05aee582b4
249789ae53c239814de8e606ff717ec9	4fb2ada7c5440a256ed0e03c967fce74
24ff2b4548c6bc357d9d9ab47882661e	17b8dff9566f6c98062ad5811c762f44
2501f7ba78cc0fd07efb7c17666ff12e	924ae2289369a9c1d279d1d59088be64
264721f3fc2aee2d28dadcdff432dbc1	17b8dff9566f6c98062ad5811c762f44
2672777b38bc4ce58c49cf4c82813a42	a29864963573d7bb061691ff823b97dd
278606b1ac0ae7ef86e86342d1f259c3	a29864963573d7bb061691ff823b97dd
278c094627c0dd891d75ea7a3d0d021e	a29864963573d7bb061691ff823b97dd
2876f7ecdae220b3c0dcb91ff13d0590	a68d5b72c2f98613f511337a59312f78
28a95ef0eabe44a27f49bbaecaa8a847	a29864963573d7bb061691ff823b97dd
28a95ef0eabe44a27f49bbaecaa8a847	d5a9c37bc91d6d5d55a3c2e38c3bf97d
28bb59d835e87f3fd813a58074ca0e11	17b8dff9566f6c98062ad5811c762f44
28bc31b338dbd482802b77ed1fd82a50	17b8dff9566f6c98062ad5811c762f44
28bc31b338dbd482802b77ed1fd82a50	a68d5b72c2f98613f511337a59312f78
28f843fa3a493a3720c4c45942ad970e	01864d382accf1cdb077e42032b16340
2a024edafb06c7882e2e1f7b57f2f951	01864d382accf1cdb077e42032b16340
2a024edafb06c7882e2e1f7b57f2f951	a68d5b72c2f98613f511337a59312f78
2aae4f711c09481c8353003202e05359	17b8dff9566f6c98062ad5811c762f44
2aae4f711c09481c8353003202e05359	a29864963573d7bb061691ff823b97dd
2ac79000a90b015badf6747312c0ccad	a68d5b72c2f98613f511337a59312f78
2ac79000a90b015badf6747312c0ccad	ea9565886c02dbdc4892412537e607d7
2af9e4497582a6faa68a42ac2d512735	d93cf30d3eb53125668057b982b433a3
2cf65e28c586eeb98daaecf6eb573e7a	04ae76937270105919847d05aee582b4
2cf65e28c586eeb98daaecf6eb573e7a	dcd00c11302e3b16333943340d6b4a6b
2cfe35095995e8dd15ab7b867e178c15	04ae76937270105919847d05aee582b4
2cfe35095995e8dd15ab7b867e178c15	585f02a68092351a078fc43a21a56564
2df8905eae6823023de6604dc5346c29	a29864963573d7bb061691ff823b97dd
2e7a848dc99bd27acb36636124855faf	deb8040131c3f6a3caf6a616b34ac482
2fa2f1801dd37d6eb9fe4e34a782e397	d5a9c37bc91d6d5d55a3c2e38c3bf97d
31d8a0a978fad885b57a685b1a0229df	10a17b42501166d3bf8fbdff7e1d52b6
32814ff4ca9a26b8d430a8c0bc8dc63e	60e1fa5bfa060b5fff1db1ca1bae4f99
32814ff4ca9a26b8d430a8c0bc8dc63e	885ba57d521cd859bacf6f76fb37ef7c
32814ff4ca9a26b8d430a8c0bc8dc63e	ea9565886c02dbdc4892412537e607d7
32af59a47b8c7e1c982ae797fc491180	1d67aeafcd3b898e05a75da0fdc01365
33b6f1b596a60fa87baef3d2c05b7c04	57a1aaebe3e5e271aca272988c802651
33b6f1b596a60fa87baef3d2c05b7c04	9c093ec7867ba1df61e27a5943168b90
33b6f1b596a60fa87baef3d2c05b7c04	f79873ac4ff0e556619b15d82f6da52c
348bcdb386eb9cb478b55a7574622b7c	17b8dff9566f6c98062ad5811c762f44
3509af6be9fe5defc1500f5c77e38563	17b8dff9566f6c98062ad5811c762f44
360c000b499120147c8472998859a9fe	17b8dff9566f6c98062ad5811c762f44
3614c45db20ee41e068c2ab7969eb3b5	763a34aaa76475a926827873753d534f
362f8cdd1065b0f33e73208eb358991d	01864d382accf1cdb077e42032b16340
362f8cdd1065b0f33e73208eb358991d	fa20a7164233ec73db640970dae420cf
3656edf3a40a25ccd00d414c9ecbb635	885ba57d521cd859bacf6f76fb37ef7c
3656edf3a40a25ccd00d414c9ecbb635	a68d5b72c2f98613f511337a59312f78
3656edf3a40a25ccd00d414c9ecbb635	ea9565886c02dbdc4892412537e607d7
36648510adbf2a3b2028197a60b5dada	02d3190ce0f08f32be33da6cc8ec8df8
36648510adbf2a3b2028197a60b5dada	7a3808eef413b514776a7202fd2cb94f
36cbc41c1c121f2c68f5776a118ea027	a29864963573d7bb061691ff823b97dd
36f969b6aeff175204078b0533eae1a0	a29864963573d7bb061691ff823b97dd
36f969b6aeff175204078b0533eae1a0	a68d5b72c2f98613f511337a59312f78
37f02eba79e0a3d29dfd6a4cf2f4d019	303d6389f4089fe9a87559515b84156d
37f02eba79e0a3d29dfd6a4cf2f4d019	4fb2ada7c5440a256ed0e03c967fce74
3964d4f40b6166aa9d370855bd20f662	a29864963573d7bb061691ff823b97dd
3964d4f40b6166aa9d370855bd20f662	a68d5b72c2f98613f511337a59312f78
39e83bc14e95fcbc05848fc33c30821f	7fa69773873856d74f68a6824ca4b691
3a2a7f86ca87268be9b9e0557b013565	a68d5b72c2f98613f511337a59312f78
3af7c6d148d216f13f66669acb8d5c59	17b8dff9566f6c98062ad5811c762f44
3af7c6d148d216f13f66669acb8d5c59	dcd00c11302e3b16333943340d6b4a6b
3bd94845163385cecefc5265a2e5a525	a29864963573d7bb061691ff823b97dd
3bd94845163385cecefc5265a2e5a525	d5a9c37bc91d6d5d55a3c2e38c3bf97d
3be3e956aeb5dc3b16285463e02af25b	8c42e2739ed83a54e5b2781b504c92de
3cdb47307aeb005121b09c41c8d8bee6	64ec11b17b6f822930f9deb757fa59e8
3d01ff8c75214314c4ca768c30e6807b	17b8dff9566f6c98062ad5811c762f44
3d2ff8abd980d730b2f4fd0abae52f60	2336f976c6d510d2a269a746a7756232
3d2ff8abd980d730b2f4fd0abae52f60	7a3808eef413b514776a7202fd2cb94f
3d2ff8abd980d730b2f4fd0abae52f60	f0095594f17b3793be8291117582f96b
3d2ff8abd980d730b2f4fd0abae52f60	fc8e55855e2f474c28507e4db7ba5f13
3d6ff25ab61ad55180a6aee9b64515bf	2df929d9b6150c082888b66e8129ee3f
3d6ff25ab61ad55180a6aee9b64515bf	7fa69773873856d74f68a6824ca4b691
3dda886448fe98771c001b56a4da9893	17b8dff9566f6c98062ad5811c762f44
3e52c77d795b7055eeff0c44687724a1	97a6395e2906e8f41d27e53a40aebae4
3e75cd2f2f6733ea4901458a7ce4236d	65d1fb3d4d28880c964b985cf335e04c
3e75cd2f2f6733ea4901458a7ce4236d	ea9565886c02dbdc4892412537e607d7
3f15c445cb553524b235b01ab75fe9a6	34d8a5e79a59df217c6882ee766c850a
3f15c445cb553524b235b01ab75fe9a6	4895247ad195629fecd388b047a739b4
401357e57c765967393ba391a338e89b	04ae76937270105919847d05aee582b4
401357e57c765967393ba391a338e89b	4cfbb125e9878528bab91d12421134d8
405c7f920b019235f244315a564a8aed	6add228b14f132e14ae9da754ef070c5
4094ffd492ba473a2a7bea1b19b1662d	a29864963573d7bb061691ff823b97dd
410d913416c022077c5c1709bf104d3c	c3ee1962dffaa352386a05e845ab9d0d
42563d0088d6ac1a47648fc7621e77c6	93cce11930403f5b3ce8938a2bde5efa
42563d0088d6ac1a47648fc7621e77c6	a68d5b72c2f98613f511337a59312f78
4261335bcdc95bd89fd530ba35afbf4c	eaa57a9b4248ce3968e718895e1c2f04
426fdc79046e281c5322161f011ce68c	17b8dff9566f6c98062ad5811c762f44
4276250c9b1b839b9508825303c5c5ae	17b8dff9566f6c98062ad5811c762f44
4366d01be1b2ddef162fc0ebb6933508	04ae76937270105919847d05aee582b4
4366d01be1b2ddef162fc0ebb6933508	dcd00c11302e3b16333943340d6b4a6b
44012166c6633196dc30563db3ffd017	a68d5b72c2f98613f511337a59312f78
443866d78de61ab3cd3e0e9bf97a34f6	4cfbb125e9878528bab91d12421134d8
4453eb658c6a304675bd52ca75fbae6d	a29864963573d7bb061691ff823b97dd
449b4d758aa7151bc1bbb24c3ffb40bb	eaa57a9b4248ce3968e718895e1c2f04
44b7bda13ac1febe84d8607ca8bbf439	a29864963573d7bb061691ff823b97dd
44f2dc3400ce17fad32a189178ae72fa	7a3808eef413b514776a7202fd2cb94f
450948d9f14e07ba5e3015c2d726b452	01864d382accf1cdb077e42032b16340
450948d9f14e07ba5e3015c2d726b452	7a3808eef413b514776a7202fd2cb94f
4548a3b9c1e31cf001041dc0d166365b	585f02a68092351a078fc43a21a56564
4548a3b9c1e31cf001041dc0d166365b	a29864963573d7bb061691ff823b97dd
457f098eeb8e1518008449e9b1cb580d	a68d5b72c2f98613f511337a59312f78
457f098eeb8e1518008449e9b1cb580d	ed8e37bad13d76c6dbeb58152440b41e
46174766ce49edbbbc40e271c87b5a83	a68d5b72c2f98613f511337a59312f78
47b23e889175dde5d6057db61cb52847	ea9565886c02dbdc4892412537e607d7
485065ad2259054abf342d7ae3fe27e6	4fb2ada7c5440a256ed0e03c967fce74
485065ad2259054abf342d7ae3fe27e6	8c42e2739ed83a54e5b2781b504c92de
4927f3218b038c780eb795766dfd04ee	885ba57d521cd859bacf6f76fb37ef7c
49c4097bae6c6ea96f552e38cfb6c2d1	a29864963573d7bb061691ff823b97dd
4a2a0d0c29a49d9126dcb19230aa1994	17b8dff9566f6c98062ad5811c762f44
4a2a0d0c29a49d9126dcb19230aa1994	a29864963573d7bb061691ff823b97dd
4a45ac6d83b85125b4163a40364e7b2c	7a3808eef413b514776a7202fd2cb94f
4a45ac6d83b85125b4163a40364e7b2c	bb273189d856ee630d92fbc0274178bb
4a45ac6d83b85125b4163a40364e7b2c	f0095594f17b3793be8291117582f96b
4a7d9e528dada8409e88865225fb27c4	273112316e7fab5a848516666e3a57d1
4a7d9e528dada8409e88865225fb27c4	ef5131009b7ced0b35ea49c8c7690cef
4b503a03f3f1aec6e5b4d53dd8148498	924ae2289369a9c1d279d1d59088be64
4b98a8c164586e11779a0ef9421ad0ee	4fb2ada7c5440a256ed0e03c967fce74
4cabe475dd501f3fd4da7273b5890c33	34d8a5e79a59df217c6882ee766c850a
4cabe475dd501f3fd4da7273b5890c33	887f0b9675f70bc312e17c93f248b5aa
4cfab0d66614c6bb6d399837656c590e	17b8dff9566f6c98062ad5811c762f44
4cfab0d66614c6bb6d399837656c590e	a29864963573d7bb061691ff823b97dd
4dddd8579760abb62aa4b1910725e73c	0138eefa704205fd48d98528ddcdd5bc
4ee21b1371ba008a26b313c7622256f8	c08ed51a7772c1f8352ad69071187515
4ee21b1371ba008a26b313c7622256f8	ff3a5da5aa221f7e16361efcccf4cbaa
4f48e858e9ed95709458e17027bb94bf	4cfbb125e9878528bab91d12421134d8
4f48e858e9ed95709458e17027bb94bf	65d1fb3d4d28880c964b985cf335e04c
4f48e858e9ed95709458e17027bb94bf	ea9565886c02dbdc4892412537e607d7
4f840b1febbbcdb12b9517cd0a91e8f4	caac3244eefed8cffee878acae427e28
4fa857a989df4e1deea676a43dceea07	10a17b42501166d3bf8fbdff7e1d52b6
5037c1968f3b239541c546d32dec39eb	4c4f4d32429ac8424cb110b4117036e4
5194c60496c6f02e8b169de9a0aa542c	6add228b14f132e14ae9da754ef070c5
51fa80e44b7555c4130bd06c53f4835c	ba60b529061c0af9afe655b44957e41b
51fa80e44b7555c4130bd06c53f4835c	de62af4f3af4adf9e8c8791071ddafe3
522b6c44eb0aedf4970f2990a2f2a812	17b8dff9566f6c98062ad5811c762f44
522b6c44eb0aedf4970f2990a2f2a812	2df929d9b6150c082888b66e8129ee3f
522b6c44eb0aedf4970f2990a2f2a812	d5a9c37bc91d6d5d55a3c2e38c3bf97d
529a1d385b4a8ca97ea7369477c7b6a7	04ae76937270105919847d05aee582b4
52b133bfecec2fba79ecf451de3cf3bb	dfda7d5357bc0afc43a89e8ac992216f
52ee4c6902f6ead006b0fb2f3e2d7771	04ae76937270105919847d05aee582b4
52ee4c6902f6ead006b0fb2f3e2d7771	1c800aa97116d9afd83204d65d50199a
53369c74c3cacdc38bdcdeda9284fe3c	2e607ef3a19cf3de029e2c5882896d33
53369c74c3cacdc38bdcdeda9284fe3c	a29864963573d7bb061691ff823b97dd
53407737e93f53afdfc588788b8288e8	36e61931478cf781e59da3b5ae2ee64e
53a0aafa942245f18098ccd58b4121aa	04ae76937270105919847d05aee582b4
5435326cf392e2cd8ad7768150cd5df6	17b8dff9566f6c98062ad5811c762f44
5447110e1e461c8c22890580c796277a	01864d382accf1cdb077e42032b16340
54b72f3169fea84731d3bcba785eac49	7fa69773873856d74f68a6824ca4b691
54f0b93fa83225e4a712b70c68c0ab6f	04ae76937270105919847d05aee582b4
55159d04cc4faebd64689d3b74a94009	7349da19c2ad6654280ecf64ce42b837
559ccea48c3460ebc349587d35e808dd	17b8dff9566f6c98062ad5811c762f44
5842a0c2470fe12ee3acfeec16c79c57	17b8dff9566f6c98062ad5811c762f44
585b13106ecfd7ede796242aeaed4ea8	04ae76937270105919847d05aee582b4
585b13106ecfd7ede796242aeaed4ea8	2a78330cc0de19f12ae9c7de65b9d5d5
585b13106ecfd7ede796242aeaed4ea8	7ac5b6239ee196614c19db6965c67b31
585b13106ecfd7ede796242aeaed4ea8	885ba57d521cd859bacf6f76fb37ef7c
585b13106ecfd7ede796242aeaed4ea8	d5d0458ada103152d94ff3828bf33909
58db028cf01dd425e5af6c7d511291c1	17b8dff9566f6c98062ad5811c762f44
5952dff7a6b1b3c94238ad3c6a42b904	02c4d46b0568d199466ef1baa339adc8
5952dff7a6b1b3c94238ad3c6a42b904	1302a3937910e1487d44cec8f9a09660
5952dff7a6b1b3c94238ad3c6a42b904	6fa3bbbff822349fee0eaf8cd78c0623
5952dff7a6b1b3c94238ad3c6a42b904	72616c6de7633d9ac97165fc7887fa3a
5952dff7a6b1b3c94238ad3c6a42b904	e7faf05839e2f549fb3455df7327942b
5952dff7a6b1b3c94238ad3c6a42b904	ef5131009b7ced0b35ea49c8c7690cef
59d153c1c2408b702189623231b7898a	a29864963573d7bb061691ff823b97dd
59f06d56c38ac98effb4c6da117b0305	7a3808eef413b514776a7202fd2cb94f
5af874093e5efcbaeb4377b84c5f2ec5	b6a0263862e208f05258353f86fa3318
5b20ea1312a1a21beaa8b86fe3a07140	2df929d9b6150c082888b66e8129ee3f
5b22d1d5846a2b6b6d0cf342e912d124	7a3808eef413b514776a7202fd2cb94f
5b709b96ee02a30be5eee558e3058245	02d3190ce0f08f32be33da6cc8ec8df8
5b709b96ee02a30be5eee558e3058245	a29864963573d7bb061691ff823b97dd
5b709b96ee02a30be5eee558e3058245	d5a9c37bc91d6d5d55a3c2e38c3bf97d
5c0adc906f34f9404d65a47eea76dac0	02d3190ce0f08f32be33da6cc8ec8df8
5c0adc906f34f9404d65a47eea76dac0	bb273189d856ee630d92fbc0274178bb
5c0adc906f34f9404d65a47eea76dac0	d5a9c37bc91d6d5d55a3c2e38c3bf97d
5cd1c3c856115627b4c3e93991f2d9cd	a29864963573d7bb061691ff823b97dd
5ce10014f645da4156ddd2cd0965986e	2336f976c6d510d2a269a746a7756232
5ce10014f645da4156ddd2cd0965986e	2e607ef3a19cf3de029e2c5882896d33
5ce10014f645da4156ddd2cd0965986e	7349da19c2ad6654280ecf64ce42b837
5df92b70e2855656e9b3ffdf313d7379	10a17b42501166d3bf8fbdff7e1d52b6
5df92b70e2855656e9b3ffdf313d7379	7fa69773873856d74f68a6824ca4b691
5e4317ada306a255748447aef73fff68	01864d382accf1cdb077e42032b16340
5e4317ada306a255748447aef73fff68	a29864963573d7bb061691ff823b97dd
5ec1e9fa36898eaf6d1021be67e0d00c	04ae76937270105919847d05aee582b4
5ec1e9fa36898eaf6d1021be67e0d00c	585f02a68092351a078fc43a21a56564
5ec1e9fa36898eaf6d1021be67e0d00c	5bf88dc6f6501943cc5bc4c42c71b36b
5efb7d24387b25d8325839be958d9adf	36e61931478cf781e59da3b5ae2ee64e
5efb7d24387b25d8325839be958d9adf	4fb2ada7c5440a256ed0e03c967fce74
5f992768f7bb9592bed35b07197c87d0	17b8dff9566f6c98062ad5811c762f44
5f992768f7bb9592bed35b07197c87d0	a29864963573d7bb061691ff823b97dd
5f992768f7bb9592bed35b07197c87d0	a68d5b72c2f98613f511337a59312f78
626dceb92e4249628c1e76a2c955cd24	7fa69773873856d74f68a6824ca4b691
6369ba49db4cf35b35a7c47e3d4a4fd0	bbc90d6701da0aa2bf7f6f2acb79e18c
6369ba49db4cf35b35a7c47e3d4a4fd0	dcd00c11302e3b16333943340d6b4a6b
63ad3072dc5472bb44c2c42ede26d90f	a29864963573d7bb061691ff823b97dd
63ae1791fc0523f47bea9485ffec8b8c	de62af4f3af4adf9e8c8791071ddafe3
63bd9a49dd18fbc89c2ec1e1b689ddda	17b8dff9566f6c98062ad5811c762f44
63d7f33143522ba270cb2c87f724b126	01864d382accf1cdb077e42032b16340
63d7f33143522ba270cb2c87f724b126	d5a9c37bc91d6d5d55a3c2e38c3bf97d
649db5c9643e1c17b3a44579980da0ad	10a17b42501166d3bf8fbdff7e1d52b6
649db5c9643e1c17b3a44579980da0ad	17b8dff9566f6c98062ad5811c762f44
652208d2aa8cdd769632dbaeb7a16358	4fb2ada7c5440a256ed0e03c967fce74
656d1497f7e25fe0559c6be81a4bccae	10a17b42501166d3bf8fbdff7e1d52b6
656d1497f7e25fe0559c6be81a4bccae	17b8dff9566f6c98062ad5811c762f44
65976b6494d411d609160a2dfd98f903	02d3190ce0f08f32be33da6cc8ec8df8
65976b6494d411d609160a2dfd98f903	2d4b3247824e58c3c9af547cce7c2c8f
65976b6494d411d609160a2dfd98f903	bb273189d856ee630d92fbc0274178bb
660813131789b822f0c75c667e23fc85	a29864963573d7bb061691ff823b97dd
660813131789b822f0c75c667e23fc85	d5a9c37bc91d6d5d55a3c2e38c3bf97d
66599a31754b5ac2a202c46c2b577c8e	17b8dff9566f6c98062ad5811c762f44
66599a31754b5ac2a202c46c2b577c8e	d5a9c37bc91d6d5d55a3c2e38c3bf97d
66599a31754b5ac2a202c46c2b577c8e	ecbff10e148109728d5ebce3341bb85e
6738f9acd4740d945178c649d6981734	e6218d584a501be9b1c36ac5ed13f2db
679eaa47efb2f814f2642966ee6bdfe1	a279b219de7726798fc2497d48bc0402
679eaa47efb2f814f2642966ee6bdfe1	d5a9c37bc91d6d5d55a3c2e38c3bf97d
6830afd7158930ca7d1959ce778eb681	34d8a5e79a59df217c6882ee766c850a
6830afd7158930ca7d1959ce778eb681	b45e0862060b7535e176f48d3e0b89f3
6a0e9ce4e2da4f2cbcd1292fddaa0ac6	2336f976c6d510d2a269a746a7756232
6b7cf117ecf0fea745c4c375c1480cb5	17b8dff9566f6c98062ad5811c762f44
6bafe8cf106c32d485c469d36c056989	2336f976c6d510d2a269a746a7756232
6bafe8cf106c32d485c469d36c056989	6de7f9aa9c912bf8c81a9ce2bfc062bd
6bd19bad2b0168d4481b19f9c25b4a9f	262770cfc76233c4f0d7a1e43a36cbf7
6bd19bad2b0168d4481b19f9c25b4a9f	885ba57d521cd859bacf6f76fb37ef7c
6c00bb1a64f660600a6c1545377f92dc	1396a3913454b8016ddf671d02e861b1
6c00bb1a64f660600a6c1545377f92dc	2336f976c6d510d2a269a746a7756232
6c1fcd3c91bc400e5c16f467d75dced3	268a3b877b5f3694d5d1964c654ca91c
6c607fc8c0adc99559bc14e01170fee1	a29864963573d7bb061691ff823b97dd
6c607fc8c0adc99559bc14e01170fee1	d5a9c37bc91d6d5d55a3c2e38c3bf97d
6d3b28f48c848a21209a84452d66c0c4	17b8dff9566f6c98062ad5811c762f44
6d3b28f48c848a21209a84452d66c0c4	a68d5b72c2f98613f511337a59312f78
6d57b25c282247075f5e03cde27814df	eaa57a9b4248ce3968e718895e1c2f04
6ee2e6d391fa98d7990b502e72c7ec58	04ae76937270105919847d05aee582b4
6f195d8f9fe09d45d2e680f7d7157541	7a3808eef413b514776a7202fd2cb94f
6f195d8f9fe09d45d2e680f7d7157541	c5405146cd45f9d9b4f02406c35315a8
6f199e29c5782bd05a4fef98e7e41419	7a3808eef413b514776a7202fd2cb94f
710ba5ed112368e3ce50e2c84b17210c	17b8dff9566f6c98062ad5811c762f44
71e32909a1bec1edfc09aec09ca2ac17	17b8dff9566f6c98062ad5811c762f44
721c28f4c74928cc9e0bb3fef345e408	17b8dff9566f6c98062ad5811c762f44
72778afd2696801f5f3a1f35d0e4e357	1eef6db16bfc0aaf8904df1503895979
72778afd2696801f5f3a1f35d0e4e357	9c093ec7867ba1df61e27a5943168b90
73affe574e6d4dc2fa72b46dc9dd4815	7a3808eef413b514776a7202fd2cb94f
73affe574e6d4dc2fa72b46dc9dd4815	d5a9c37bc91d6d5d55a3c2e38c3bf97d
73affe574e6d4dc2fa72b46dc9dd4815	f41da0c65a8fa3690e6a6877e7112afb
7462f03404f29ea618bcc9d52de8e647	04ae76937270105919847d05aee582b4
7462f03404f29ea618bcc9d52de8e647	17b8dff9566f6c98062ad5811c762f44
7462f03404f29ea618bcc9d52de8e647	a29864963573d7bb061691ff823b97dd
7463543d784aa59ca86359a50ef58c8e	17b8dff9566f6c98062ad5811c762f44
7463543d784aa59ca86359a50ef58c8e	a29864963573d7bb061691ff823b97dd
7492a1ca2669793b485b295798f5d782	6add228b14f132e14ae9da754ef070c5
74b3b7be6ed71b946a151d164ad8ede5	b7d08853c905c8cd1467f7bdf0dc176f
7533f96ec01fd81438833f71539c7d4e	04ae76937270105919847d05aee582b4
75ab0270163731ee05f35640d56ef473	c08ed51a7772c1f8352ad69071187515
75ab0270163731ee05f35640d56ef473	dcd00c11302e3b16333943340d6b4a6b
76700087e932c3272e05694610d604ba	a68d5b72c2f98613f511337a59312f78
776da10f7e18ffde35ea94d144dc60a3	01864d382accf1cdb077e42032b16340
7771012413f955f819866e517b275cb4	17b8dff9566f6c98062ad5811c762f44
7771012413f955f819866e517b275cb4	a29864963573d7bb061691ff823b97dd
77f2b3ea9e4bd785f5ff322bae51ba07	01864d382accf1cdb077e42032b16340
77f2b3ea9e4bd785f5ff322bae51ba07	4fb2ada7c5440a256ed0e03c967fce74
79566192cda6b33a9ff59889eede2d66	2e607ef3a19cf3de029e2c5882896d33
79566192cda6b33a9ff59889eede2d66	a29864963573d7bb061691ff823b97dd
79ce9bd96a3184b1ee7c700aa2927e67	17b8dff9566f6c98062ad5811c762f44
79ce9bd96a3184b1ee7c700aa2927e67	a29864963573d7bb061691ff823b97dd
7a4fafa7badd04d5d3114ab67b0caf9d	0849fb9eb585f2c20b427a99f1231e40
7c7ab6fbcb47bd5df1e167ca28220ee9	7a3808eef413b514776a7202fd2cb94f
7c7ab6fbcb47bd5df1e167ca28220ee9	caac3244eefed8cffee878acae427e28
7c83727aa466b3b1b9d6556369714fcf	02d3190ce0f08f32be33da6cc8ec8df8
7c83727aa466b3b1b9d6556369714fcf	10a17b42501166d3bf8fbdff7e1d52b6
7c83727aa466b3b1b9d6556369714fcf	1c800aa97116d9afd83204d65d50199a
7c83727aa466b3b1b9d6556369714fcf	5bf88dc6f6501943cc5bc4c42c71b36b
7cd7921da2e6aab79c441a0c2ffc969b	17b8dff9566f6c98062ad5811c762f44
7cd7921da2e6aab79c441a0c2ffc969b	36e61931478cf781e59da3b5ae2ee64e
7cd7921da2e6aab79c441a0c2ffc969b	885ba57d521cd859bacf6f76fb37ef7c
7cd7921da2e6aab79c441a0c2ffc969b	f41da0c65a8fa3690e6a6877e7112afb
7d6b45c02283175f490558068d1fc81b	34d8a5e79a59df217c6882ee766c850a
7d6b45c02283175f490558068d1fc81b	d5a9c37bc91d6d5d55a3c2e38c3bf97d
7d878673694ff2498fbea0e5ba27e0ea	17b8dff9566f6c98062ad5811c762f44
7db066b46f48d010fdb8c87337cdeda4	6de7f9aa9c912bf8c81a9ce2bfc062bd
7df8865bbec157552b8a579e0ed9bfe3	04ae76937270105919847d05aee582b4
7df8865bbec157552b8a579e0ed9bfe3	a29864963573d7bb061691ff823b97dd
7df8865bbec157552b8a579e0ed9bfe3	bb273189d856ee630d92fbc0274178bb
7df8865bbec157552b8a579e0ed9bfe3	d5a9c37bc91d6d5d55a3c2e38c3bf97d
7df8865bbec157552b8a579e0ed9bfe3	dcd00c11302e3b16333943340d6b4a6b
7dfe9aa0ca5bb31382879ccd144cc3ae	5cbdaf6af370a627c84c43743e99e016
7e0d5240ec5d34a30b6f24909e5edcb4	2336f976c6d510d2a269a746a7756232
7e0d5240ec5d34a30b6f24909e5edcb4	2e607ef3a19cf3de029e2c5882896d33
7e0d5240ec5d34a30b6f24909e5edcb4	a29864963573d7bb061691ff823b97dd
7e2b83d69e6c93adf203e13bc7d6f444	10a17b42501166d3bf8fbdff7e1d52b6
7e2b83d69e6c93adf203e13bc7d6f444	17b8dff9566f6c98062ad5811c762f44
7eaf9a47aa47f3c65595ae107feab05d	7a3808eef413b514776a7202fd2cb94f
7ef36a3325a61d4f1cff91acbe77c7e3	0138eefa704205fd48d98528ddcdd5bc
7f29efc2495ce308a8f4aa7bfc11d701	94876c8f843fa0641ed7bdf6562bdbcf
7fc454efb6df96e012e0f937723d24aa	17b8dff9566f6c98062ad5811c762f44
804803e43d2c779d00004a6e87f28e30	a29864963573d7bb061691ff823b97dd
80fcd08f6e887f6cfbedd2156841ab2b	e7faf05839e2f549fb3455df7327942b
8143ee8032c71f6f3f872fc5bb2a4fed	17b8dff9566f6c98062ad5811c762f44
8143ee8032c71f6f3f872fc5bb2a4fed	d5a9c37bc91d6d5d55a3c2e38c3bf97d
8143ee8032c71f6f3f872fc5bb2a4fed	f41da0c65a8fa3690e6a6877e7112afb
820de5995512273916b117944d6da15a	01864d382accf1cdb077e42032b16340
828d51c39c87aad9b1407d409fa58e36	2e607ef3a19cf3de029e2c5882896d33
829922527f0e7d64a3cfda67e24351e3	17b8dff9566f6c98062ad5811c762f44
829922527f0e7d64a3cfda67e24351e3	caac3244eefed8cffee878acae427e28
832dd1d8efbdb257c2c7d3e505142f48	ff7aa8ca226e1b753b0a71d7f0f2e174
8589a6a4d8908d7e8813e9a1c5693d70	7fa69773873856d74f68a6824ca4b691
86482a1e94052aa18cd803a51104cdb9	2894c332092204f7389275e1359f8e9b
8654991720656374d632a5bb0c20ff11	1d67aeafcd3b898e05a75da0fdc01365
8654991720656374d632a5bb0c20ff11	239401e2c0d502df7c9009439bdb5bd3
8654991720656374d632a5bb0c20ff11	4428b837e98e3cc023fc5cd583b28b20
8775f64336ee5e9a8114fbe3a5a628c5	60e1fa5bfa060b5fff1db1ca1bae4f99
8775f64336ee5e9a8114fbe3a5a628c5	f224a37b854811cb14412ceeca43a6ad
87ded0ea2f4029da0a0022000d59232b	2df929d9b6150c082888b66e8129ee3f
87f44124fb8d24f4c832138baede45c7	04ae76937270105919847d05aee582b4
87f44124fb8d24f4c832138baede45c7	885ba57d521cd859bacf6f76fb37ef7c
88711444ece8fe638ae0fb11c64e2df3	924ae2289369a9c1d279d1d59088be64
887d6449e3544dca547a2ddba8f2d894	a29864963573d7bb061691ff823b97dd
889aaf9cd0894206af758577cf5cf071	17b8dff9566f6c98062ad5811c762f44
88dd124c0720845cba559677f3afa15d	10a17b42501166d3bf8fbdff7e1d52b6
891a55e21dfacf2f97c450c77e7c3ea7	2336f976c6d510d2a269a746a7756232
891a55e21dfacf2f97c450c77e7c3ea7	2e607ef3a19cf3de029e2c5882896d33
8945663993a728ab19a3853e5b820a42	585f02a68092351a078fc43a21a56564
897edb97d775897f69fa168a88b01c19	2df929d9b6150c082888b66e8129ee3f
897edb97d775897f69fa168a88b01c19	7fa69773873856d74f68a6824ca4b691
89adcf990042dfdac7fd23685b3f1e37	65d1fb3d4d28880c964b985cf335e04c
89adcf990042dfdac7fd23685b3f1e37	ea9565886c02dbdc4892412537e607d7
8a6f1a01e4b0d9e272126a8646a72088	01864d382accf1cdb077e42032b16340
8b0ee5a501cef4a5699fd3b2d4549e8f	04ae76937270105919847d05aee582b4
8b0ee5a501cef4a5699fd3b2d4549e8f	a29864963573d7bb061691ff823b97dd
8b427a493fc39574fc801404bc032a2f	1396a3913454b8016ddf671d02e861b1
8b427a493fc39574fc801404bc032a2f	2a78330cc0de19f12ae9c7de65b9d5d5
8b427a493fc39574fc801404bc032a2f	ad49b27a742fb199ab722bce67e9c7b2
8bc31f7cc79c177ab7286dda04e2d1e5	7349da19c2ad6654280ecf64ce42b837
8bc31f7cc79c177ab7286dda04e2d1e5	d31813e8ef36490c57d4977e637efbd4
8bc31f7cc79c177ab7286dda04e2d1e5	ef5131009b7ced0b35ea49c8c7690cef
8c69497eba819ee79a964a0d790368fb	17b8dff9566f6c98062ad5811c762f44
8c69497eba819ee79a964a0d790368fb	a29864963573d7bb061691ff823b97dd
8ce896355a45f5b9959eb676b8b5580c	320094e3f180ee372243f1161e9adadc
8d7a18d54e82fcfb7a11566ce94b9109	04ae76937270105919847d05aee582b4
8d7a18d54e82fcfb7a11566ce94b9109	a29864963573d7bb061691ff823b97dd
8e11b2f987a99ed900a44aa1aa8bd3d0	04ae76937270105919847d05aee582b4
8e62fc75d9d0977d0be4771df05b3c2f	fbe238aca6c496dcd05fb8d6d98f275b
8edf4531385941dfc85e3f3d3e32d24f	7886613ffb324e4e0065f25868545a63
8edf4531385941dfc85e3f3d3e32d24f	7a3808eef413b514776a7202fd2cb94f
8edfa58b1aedb58629b80e5be2b2bd92	1c800aa97116d9afd83204d65d50199a
8edfa58b1aedb58629b80e5be2b2bd92	5bf88dc6f6501943cc5bc4c42c71b36b
8edfa58b1aedb58629b80e5be2b2bd92	7a3808eef413b514776a7202fd2cb94f
8f1f10cb698cb995fd69a671af6ecd58	fd00614e73cb66fd71ab13c970a074d8
8fda25275801e4a40df6c73078baf753	01864d382accf1cdb077e42032b16340
8fda25275801e4a40df6c73078baf753	d5a9c37bc91d6d5d55a3c2e38c3bf97d
905a40c3533830252a909603c6fa1e6a	17b8dff9566f6c98062ad5811c762f44
90d127641ffe2a600891cd2e3992685b	a29864963573d7bb061691ff823b97dd
90d523ebbf276f516090656ebfccdc9f	4cfbb125e9878528bab91d12421134d8
90d523ebbf276f516090656ebfccdc9f	60e1fa5bfa060b5fff1db1ca1bae4f99
9138c2cc0326412f2515623f4c850eb3	17b8dff9566f6c98062ad5811c762f44
91a337f89fe65fec1c97f52a821c1178	a68d5b72c2f98613f511337a59312f78
4bb93d90453dd63cc1957a033f7855c7	17b8dff9566f6c98062ad5811c762f44
4bb93d90453dd63cc1957a033f7855c7	7a3808eef413b514776a7202fd2cb94f
4bb93d90453dd63cc1957a033f7855c7	a29864963573d7bb061691ff823b97dd
91b18e22d4963b216af00e1dd43b5d05	f0095594f17b3793be8291117582f96b
91b18e22d4963b216af00e1dd43b5d05	fad6ee4f3b0aded7d0974703e35ae032
91c9ed0262dea7446a4f3a3e1cdd0698	04ae76937270105919847d05aee582b4
91c9ed0262dea7446a4f3a3e1cdd0698	585f02a68092351a078fc43a21a56564
925bd435e2718d623768dbf1bc1cfb60	10a17b42501166d3bf8fbdff7e1d52b6
925bd435e2718d623768dbf1bc1cfb60	7fa69773873856d74f68a6824ca4b691
935b48a84528c4280ec208ce529deea0	7fa69773873856d74f68a6824ca4b691
942c9f2520684c22eb6216a92b711f9e	01864d382accf1cdb077e42032b16340
947ce14614263eab49f780d68555aef8	7fa69773873856d74f68a6824ca4b691
948098e746bdf1c1045c12f042ea98c2	924ae2289369a9c1d279d1d59088be64
952dc6362e304f00575264e9d54d1fa6	17b8dff9566f6c98062ad5811c762f44
96682d9c9f1bed695dbf9176d3ee234c	a29864963573d7bb061691ff823b97dd
97ee29f216391d19f8769f79a1218a71	0cf6ece7453aa814e08cb7c33bd39846
97ee29f216391d19f8769f79a1218a71	17b8dff9566f6c98062ad5811c762f44
97ee29f216391d19f8769f79a1218a71	a68d5b72c2f98613f511337a59312f78
988d10abb9f42e7053450af19ad64c7f	10a17b42501166d3bf8fbdff7e1d52b6
988d10abb9f42e7053450af19ad64c7f	781f547374aef3a99c113ad5a9c12981
990813672e87b667add44c712bb28d3d	17b8dff9566f6c98062ad5811c762f44
990813672e87b667add44c712bb28d3d	a68d5b72c2f98613f511337a59312f78
99bd5eff92fc3ba728a9da5aa1971488	1868ffbe3756a1c3f58300f45aa5e1d3
9a322166803a48932356586f05ef83c7	01864d382accf1cdb077e42032b16340
9ab8f911c74597493400602dc4d2b412	04ae76937270105919847d05aee582b4
9ab8f911c74597493400602dc4d2b412	4fb2ada7c5440a256ed0e03c967fce74
9ab8f911c74597493400602dc4d2b412	585f02a68092351a078fc43a21a56564
9b1088b616414d0dc515ab1f2b4922f1	a29864963573d7bb061691ff823b97dd
9bc2ca9505a273b06aa0b285061cd1de	17b8dff9566f6c98062ad5811c762f44
9cf73d0300eea453f17c6faaeb871c55	17b8dff9566f6c98062ad5811c762f44
9d3ac6904ce73645c6234803cd7e47ca	239401e2c0d502df7c9009439bdb5bd3
9d969d25c9f506c5518bb090ad5f8266	924ae2289369a9c1d279d1d59088be64
9db9bc745a7568b51b3a968d215ddad6	8c42e2739ed83a54e5b2781b504c92de
9db9bc745a7568b51b3a968d215ddad6	e8376ca6a0ac30b2ad0d64de6061adab
9e84832a15f2698f67079a3224c2b6fb	7fa69773873856d74f68a6824ca4b691
9e84832a15f2698f67079a3224c2b6fb	deb8040131c3f6a3caf6a616b34ac482
9f19396638dd8111f2cee938fdf4e455	17b8dff9566f6c98062ad5811c762f44
a332f1280622f9628fccd1b7aac7370a	239401e2c0d502df7c9009439bdb5bd3
a332f1280622f9628fccd1b7aac7370a	f41da0c65a8fa3690e6a6877e7112afb
a3f5542dc915b94a5e10dab658bb0959	8c42e2739ed83a54e5b2781b504c92de
a3f5542dc915b94a5e10dab658bb0959	a68d5b72c2f98613f511337a59312f78
a3f5542dc915b94a5e10dab658bb0959	e8376ca6a0ac30b2ad0d64de6061adab
a4902fb3d5151e823c74dfd51551b4b0	bca74411b74f01449c61b29131bc545e
a4902fb3d5151e823c74dfd51551b4b0	c1bfb800f95ae493952b6db9eb4f0209
a4902fb3d5151e823c74dfd51551b4b0	d5d0458ada103152d94ff3828bf33909
a4902fb3d5151e823c74dfd51551b4b0	dcd00c11302e3b16333943340d6b4a6b
a4977b96c7e5084fcce21a0d07b045f8	0cf6ece7453aa814e08cb7c33bd39846
a4cbfb212102da21b82d94be555ac3ec	17b8dff9566f6c98062ad5811c762f44
a538bfe6fe150a92a72d78f89733dbd0	17b8dff9566f6c98062ad5811c762f44
a538bfe6fe150a92a72d78f89733dbd0	a68d5b72c2f98613f511337a59312f78
a61b878c2b563f289de2109fa0f42144	65805a3772889203be8908bb44d964b3
a61b878c2b563f289de2109fa0f42144	885ba57d521cd859bacf6f76fb37ef7c
a650d82df8ca65bb69a45242ab66b399	01864d382accf1cdb077e42032b16340
a716390764a4896d99837e99f9e009c9	a29864963573d7bb061691ff823b97dd
a7a9c1b4e7f10bd1fdf77aff255154f7	02d3190ce0f08f32be33da6cc8ec8df8
a7a9c1b4e7f10bd1fdf77aff255154f7	1302a3937910e1487d44cec8f9a09660
a7a9c1b4e7f10bd1fdf77aff255154f7	bb273189d856ee630d92fbc0274178bb
a7a9c1b4e7f10bd1fdf77aff255154f7	dcd00c11302e3b16333943340d6b4a6b
a7a9c1b4e7f10bd1fdf77aff255154f7	ff7aa8ca226e1b753b0a71d7f0f2e174
a7f9797e4cd716e1516f9d4845b0e1e2	2e607ef3a19cf3de029e2c5882896d33
a7f9797e4cd716e1516f9d4845b0e1e2	a29864963573d7bb061691ff823b97dd
a825b2b87f3b61c9660b81f340f6e519	b7628553175256a081199e493d97bd3b
a8d9eeed285f1d47836a5546a280a256	a29864963573d7bb061691ff823b97dd
aa0d528ba11ea1485d466dfe1ea40819	17b8dff9566f6c98062ad5811c762f44
aa0d528ba11ea1485d466dfe1ea40819	a29864963573d7bb061691ff823b97dd
aa86b6fc103fc757e14f03afe6eb0c0a	a68d5b72c2f98613f511337a59312f78
abbf8e3e3c3e78be8bd886484c1283c1	a68d5b72c2f98613f511337a59312f78
abd7ab19ff758cf4c1a2667e5bbac444	deb8040131c3f6a3caf6a616b34ac482
ac03fad3be179a237521ec4ef2620fb0	04ae76937270105919847d05aee582b4
ac94d15f46f10707a39c4bc513cd9f98	2df929d9b6150c082888b66e8129ee3f
ac94d15f46f10707a39c4bc513cd9f98	7fa69773873856d74f68a6824ca4b691
ad01952b3c254c8ebefaf6f73ae62f7d	17b8dff9566f6c98062ad5811c762f44
ad62209fb63910acf40280cea3647ec5	10a17b42501166d3bf8fbdff7e1d52b6
ad62209fb63910acf40280cea3647ec5	17b8dff9566f6c98062ad5811c762f44
ad62209fb63910acf40280cea3647ec5	d5a9c37bc91d6d5d55a3c2e38c3bf97d
ade72e999b4e78925b18cf48d1faafa4	caac3244eefed8cffee878acae427e28
aed85c73079b54830cd50a75c0958a90	17b8dff9566f6c98062ad5811c762f44
b01fbaf98cfbc1b72e8bca0b2e48769c	781f547374aef3a99c113ad5a9c12981
b0ce1e93de9839d07dab8d268ca23728	3770d5a677c09a444a026dc7434bff36
b0ce1e93de9839d07dab8d268ca23728	f0095594f17b3793be8291117582f96b
b14814d0ee12ffadc8f09ab9c604a9d0	a29864963573d7bb061691ff823b97dd
b1bdad87bd3c4ac2c22473846d301a9e	7fa69773873856d74f68a6824ca4b691
b1d465aaf3ccf8701684211b1623adf2	4fb2ada7c5440a256ed0e03c967fce74
b3ffff8517114caf70b9e70734dbaf6f	01864d382accf1cdb077e42032b16340
b3ffff8517114caf70b9e70734dbaf6f	a29864963573d7bb061691ff823b97dd
b570e354b7ebc40e20029fcc7a15e5a7	8dae638cc517185f1e6f065fcd5e8af3
b5d9c5289fe97968a5634b3e138bf9e2	2df929d9b6150c082888b66e8129ee3f
b5d9c5289fe97968a5634b3e138bf9e2	7fa69773873856d74f68a6824ca4b691
b5d9c5289fe97968a5634b3e138bf9e2	caac3244eefed8cffee878acae427e28
b5f7b25b0154c34540eea8965f90984d	04ae76937270105919847d05aee582b4
b5f7b25b0154c34540eea8965f90984d	4cfbb125e9878528bab91d12421134d8
b5f7b25b0154c34540eea8965f90984d	dcd00c11302e3b16333943340d6b4a6b
b6da055500e3d92698575a3cfc74906c	1c800aa97116d9afd83204d65d50199a
b6da055500e3d92698575a3cfc74906c	5bf88dc6f6501943cc5bc4c42c71b36b
b6da055500e3d92698575a3cfc74906c	7a3808eef413b514776a7202fd2cb94f
b885447285ece8226facd896c04cdba2	a29864963573d7bb061691ff823b97dd
b885447285ece8226facd896c04cdba2	d5a9c37bc91d6d5d55a3c2e38c3bf97d
b89e91ccf14bfd7f485dd7be7d789b0a	02c4d46b0568d199466ef1baa339adc8
b89e91ccf14bfd7f485dd7be7d789b0a	2336f976c6d510d2a269a746a7756232
b89e91ccf14bfd7f485dd7be7d789b0a	8dae638cc517185f1e6f065fcd5e8af3
b89e91ccf14bfd7f485dd7be7d789b0a	ef5131009b7ced0b35ea49c8c7690cef
b96a3cb81197e8308c87f6296174fe3e	a29864963573d7bb061691ff823b97dd
baa9d4eef21c7b89f42720313b5812d4	7fa69773873856d74f68a6824ca4b691
baa9d4eef21c7b89f42720313b5812d4	caac3244eefed8cffee878acae427e28
baa9d4eef21c7b89f42720313b5812d4	e22aa8f4c79b6c4bbeb6bcc7f4e1eb26
bb4cc149e8027369e71eb1bb36cd98e0	c1bfb800f95ae493952b6db9eb4f0209
bb4cc149e8027369e71eb1bb36cd98e0	d5d0458ada103152d94ff3828bf33909
bbb668ff900efa57d936e726a09e4fe8	8c42e2739ed83a54e5b2781b504c92de
bbc155fb2b111bf61c4f5ff892915e6b	1c800aa97116d9afd83204d65d50199a
bbce8e45250a239a252752fac7137e00	7a3808eef413b514776a7202fd2cb94f
bbce8e45250a239a252752fac7137e00	ff7aa8ca226e1b753b0a71d7f0f2e174
bd4184ee062e4982b878b6b188793f5b	585f02a68092351a078fc43a21a56564
bd4184ee062e4982b878b6b188793f5b	a68d5b72c2f98613f511337a59312f78
be20385e18333edb329d4574f364a1f0	17b8dff9566f6c98062ad5811c762f44
be20385e18333edb329d4574f364a1f0	a68d5b72c2f98613f511337a59312f78
bfc9ace5d2a11fae56d038d68c601f00	caac3244eefed8cffee878acae427e28
c05d504b806ad065c9b548c0cb1334cd	a29864963573d7bb061691ff823b97dd
c05d504b806ad065c9b548c0cb1334cd	d5a9c37bc91d6d5d55a3c2e38c3bf97d
c127f32dc042184d12b8c1433a77e8c4	1396a3913454b8016ddf671d02e861b1
c127f32dc042184d12b8c1433a77e8c4	2a78330cc0de19f12ae9c7de65b9d5d5
c127f32dc042184d12b8c1433a77e8c4	bbc90d6701da0aa2bf7f6f2acb79e18c
c127f32dc042184d12b8c1433a77e8c4	d5d0458ada103152d94ff3828bf33909
c127f32dc042184d12b8c1433a77e8c4	dcd00c11302e3b16333943340d6b4a6b
c1923ca7992dc6e79d28331abbb64e72	2df929d9b6150c082888b66e8129ee3f
c2855b6617a1b08fed3824564e15a653	caac3244eefed8cffee878acae427e28
c3490492512b7fe65cdb0c7305044675	5b412998332f677ddcc911605985ee3b
c4678a2e0eef323aeb196670f2bc8a6e	7fa69773873856d74f68a6824ca4b691
c4c7cb77b45a448aa3ca63082671ad97	17b8dff9566f6c98062ad5811c762f44
c4c7cb77b45a448aa3ca63082671ad97	caac3244eefed8cffee878acae427e28
c4c7cb77b45a448aa3ca63082671ad97	d5a9c37bc91d6d5d55a3c2e38c3bf97d
c4ddbffb73c1c34d20bd5b3f425ce4b1	8c42e2739ed83a54e5b2781b504c92de
c4f0f5cedeffc6265ec3220ab594d56b	2bd0f5e2048d09734470145332ecdd24
c5dc33e23743fb951b3fe7f1f477b794	e8376ca6a0ac30b2ad0d64de6061adab
c5f022ef2f3211dc1e3b8062ffe764f0	17b8dff9566f6c98062ad5811c762f44
c74b5aa120021cbe18dcddd70d8622da	a29864963573d7bb061691ff823b97dd
c883319a1db14bc28eff8088c5eba10e	ad38eede5e5edecd3903f1701acecf8e
c883319a1db14bc28eff8088c5eba10e	b86219c2df5a0d889f490f88ff22e228
ca5a010309ffb20190558ec20d97e5b2	a68d5b72c2f98613f511337a59312f78
ca5a010309ffb20190558ec20d97e5b2	cbfeef2f0e2cd992e0ea65924a0f28a1
ca5a010309ffb20190558ec20d97e5b2	f41da0c65a8fa3690e6a6877e7112afb
cafe9e68e8f90b3e1328da8858695b31	a29864963573d7bb061691ff823b97dd
cd9483c1733b17f57d11a77c9404893c	2336f976c6d510d2a269a746a7756232
cd9483c1733b17f57d11a77c9404893c	7349da19c2ad6654280ecf64ce42b837
cd9483c1733b17f57d11a77c9404893c	bb273189d856ee630d92fbc0274178bb
cd9483c1733b17f57d11a77c9404893c	ef5131009b7ced0b35ea49c8c7690cef
cddf835bea180bd14234a825be7a7a82	17b8dff9566f6c98062ad5811c762f44
ce2caf05154395724e4436f042b8fa53	924ae2289369a9c1d279d1d59088be64
cf4ee20655dd3f8f0a553c73ffe3f72a	f633e7b30932bbf60ed87e8ebc26839d
d05a0e65818a69cc689b38c0c0007834	a29864963573d7bb061691ff823b97dd
d0a1fd0467dc892f0dc27711637c864e	1868ffbe3756a1c3f58300f45aa5e1d3
d1fb4e47d8421364f49199ee395ad1d3	17b8dff9566f6c98062ad5811c762f44
d1fb4e47d8421364f49199ee395ad1d3	a68d5b72c2f98613f511337a59312f78
d2ff1e521585a91a94fb22752dd0ab45	17b8dff9566f6c98062ad5811c762f44
d39d7a2bb6d430fd238a6aedc7f0cee2	1c800aa97116d9afd83204d65d50199a
d39d7a2bb6d430fd238a6aedc7f0cee2	4c4f4d32429ac8424cb110b4117036e4
d3e98095eeccaa253050d67210ef02bb	1c800aa97116d9afd83204d65d50199a
d3e98095eeccaa253050d67210ef02bb	2e607ef3a19cf3de029e2c5882896d33
d3e98095eeccaa253050d67210ef02bb	7349da19c2ad6654280ecf64ce42b837
d3e98095eeccaa253050d67210ef02bb	d3fcef9d7f88d2a12ea460c604731cd5
d3ed8223151e14b936436c336a4c7278	a68d5b72c2f98613f511337a59312f78
d433b7c1ce696b94a8d8f72de6cfbeaa	a68d5b72c2f98613f511337a59312f78
d433b7c1ce696b94a8d8f72de6cfbeaa	ed8e37bad13d76c6dbeb58152440b41e
d449a9b2eed8b0556dc7be9cda36b67b	7a3808eef413b514776a7202fd2cb94f
d449a9b2eed8b0556dc7be9cda36b67b	836ea59914cc7a8e81ee0dd63f7c21c1
d449a9b2eed8b0556dc7be9cda36b67b	f0095594f17b3793be8291117582f96b
d6de9c99f5cfa46352b2bc0be5c98c41	17b8dff9566f6c98062ad5811c762f44
d730e65d54d6c0479561d25724afd813	04ae76937270105919847d05aee582b4
d730e65d54d6c0479561d25724afd813	585f02a68092351a078fc43a21a56564
d73310b95e8b4dece44e2a55dd1274e6	01864d382accf1cdb077e42032b16340
d73310b95e8b4dece44e2a55dd1274e6	d5a9c37bc91d6d5d55a3c2e38c3bf97d
d857ab11d383a7e4d4239a54cbf2a63d	10a17b42501166d3bf8fbdff7e1d52b6
d857ab11d383a7e4d4239a54cbf2a63d	17b8dff9566f6c98062ad5811c762f44
d9ab6b54c3bd5b212e8dc3a14e7699ef	60e1fa5bfa060b5fff1db1ca1bae4f99
d9ab6b54c3bd5b212e8dc3a14e7699ef	885ba57d521cd859bacf6f76fb37ef7c
d9ab6b54c3bd5b212e8dc3a14e7699ef	ea9565886c02dbdc4892412537e607d7
da2110633f62b16a571c40318e4e4c1c	17095255b1df76ab27dd48f29b215a5f
da867941c8bacf9be8e59bc13d765f92	2df929d9b6150c082888b66e8129ee3f
da867941c8bacf9be8e59bc13d765f92	7fa69773873856d74f68a6824ca4b691
db38e12f9903b156f9dc91fce2ef3919	a29864963573d7bb061691ff823b97dd
db46d9a37b31baa64cb51604a2e4939a	caac3244eefed8cffee878acae427e28
dcabc7299e2b9ed5b05c33273e5fdd19	17b8dff9566f6c98062ad5811c762f44
dcff9a127428ffb03fc02fdf6cc39575	04ae76937270105919847d05aee582b4
dcff9a127428ffb03fc02fdf6cc39575	5bf88dc6f6501943cc5bc4c42c71b36b
dcff9a127428ffb03fc02fdf6cc39575	dcd00c11302e3b16333943340d6b4a6b
dd18fa7a5052f2bce8ff7cb4a30903ea	deb8040131c3f6a3caf6a616b34ac482
dddb04bc0d058486d0ef0212c6ea0682	7fa69773873856d74f68a6824ca4b691
de12bbf91bc797df25ab4ae9cee1946b	585f02a68092351a078fc43a21a56564
de12bbf91bc797df25ab4ae9cee1946b	a29864963573d7bb061691ff823b97dd
deaccc41a952e269107cc9a507dfa131	bbc90d6701da0aa2bf7f6f2acb79e18c
deaccc41a952e269107cc9a507dfa131	dcd00c11302e3b16333943340d6b4a6b
dfdef9b5190f331de20fe029babf032e	0cf6ece7453aa814e08cb7c33bd39846
dfdef9b5190f331de20fe029babf032e	9c093ec7867ba1df61e27a5943168b90
e08383c479d96a8a762e23a99fd8bf84	2bd0f5e2048d09734470145332ecdd24
e08383c479d96a8a762e23a99fd8bf84	a68d5b72c2f98613f511337a59312f78
e08383c479d96a8a762e23a99fd8bf84	e8376ca6a0ac30b2ad0d64de6061adab
e0c2b0cc2e71294cd86916807fef62cb	04ae76937270105919847d05aee582b4
e0de9c10bbf73520385ea5dcbdf62073	7a3808eef413b514776a7202fd2cb94f
e0f39406f0e15487dd9d3997b2f5ca61	2336f976c6d510d2a269a746a7756232
e0f39406f0e15487dd9d3997b2f5ca61	2e607ef3a19cf3de029e2c5882896d33
e0f39406f0e15487dd9d3997b2f5ca61	a29864963573d7bb061691ff823b97dd
e1db3add02ca4c1af33edc5a970a3bdc	04ae76937270105919847d05aee582b4
e1db3add02ca4c1af33edc5a970a3bdc	585f02a68092351a078fc43a21a56564
e271e871e304f59e62a263ffe574ea2d	17b8dff9566f6c98062ad5811c762f44
e271e871e304f59e62a263ffe574ea2d	caac3244eefed8cffee878acae427e28
e29ef4beb480eab906ffa7c05aeec23d	17b8dff9566f6c98062ad5811c762f44
e29ef4beb480eab906ffa7c05aeec23d	a29864963573d7bb061691ff823b97dd
e3f0bf612190af6c3fad41214115e004	04ae76937270105919847d05aee582b4
e4b3296f8a9e2a378eb3eb9576b91a37	17b8dff9566f6c98062ad5811c762f44
e61e30572fd58669ae9ea410774e0eb6	17b8dff9566f6c98062ad5811c762f44
e61e30572fd58669ae9ea410774e0eb6	a68d5b72c2f98613f511337a59312f78
e62a773154e1179b0cc8c5592207cb10	04ae76937270105919847d05aee582b4
e62a773154e1179b0cc8c5592207cb10	585f02a68092351a078fc43a21a56564
e64b94f14765cee7e05b4bec8f5fee31	4cfbb125e9878528bab91d12421134d8
e64d38b05d197d60009a43588b2e4583	0cf6ece7453aa814e08cb7c33bd39846
e64d38b05d197d60009a43588b2e4583	17b8dff9566f6c98062ad5811c762f44
e64d38b05d197d60009a43588b2e4583	4cfbb125e9878528bab91d12421134d8
e64d38b05d197d60009a43588b2e4583	885ba57d521cd859bacf6f76fb37ef7c
e67e51d5f41cfc9162ef7fd977d1f9f5	7fa69773873856d74f68a6824ca4b691
e74a88c71835c14d92d583a1ed87cc6c	a29864963573d7bb061691ff823b97dd
e74a88c71835c14d92d583a1ed87cc6c	a68d5b72c2f98613f511337a59312f78
e872b77ff7ac24acc5fa373ebe9bb492	02d3190ce0f08f32be33da6cc8ec8df8
e872b77ff7ac24acc5fa373ebe9bb492	2e9dfd2e07792b56179212f5b8f473e6
e872b77ff7ac24acc5fa373ebe9bb492	72616c6de7633d9ac97165fc7887fa3a
e872b77ff7ac24acc5fa373ebe9bb492	8bbab0ae4d00ad9ffee6cddaf9338584
e872b77ff7ac24acc5fa373ebe9bb492	ad6296818a1cb902ac5d1a3950e79dbe
e872b77ff7ac24acc5fa373ebe9bb492	bfd67ea5a2f5557126b299e33a435ab3
e872b77ff7ac24acc5fa373ebe9bb492	ff7aa8ca226e1b753b0a71d7f0f2e174
e8afde257f8a2cbbd39d866ddfc06103	10a17b42501166d3bf8fbdff7e1d52b6
e8afde257f8a2cbbd39d866ddfc06103	17b8dff9566f6c98062ad5811c762f44
eb2c788da4f36fba18b85ae75aff0344	a68d5b72c2f98613f511337a59312f78
ed24ff8971b1fa43a1efbb386618ce35	17b8dff9566f6c98062ad5811c762f44
ee69e7d19f11ca58843ec2e9e77ddb38	17b8dff9566f6c98062ad5811c762f44
eeaeec364c925e0c821660c7a953546e	1c800aa97116d9afd83204d65d50199a
ef6369d9794dbe861a56100e92a3c71d	2bd0f5e2048d09734470145332ecdd24
f042da2a954a1521114551a6f9e22c75	a29864963573d7bb061691ff823b97dd
f07c3eef5b7758026d45a12c7e2f6134	4b3bb0b44a6aa876b9e125a2c2a5d6a2
f0c051b57055b052a3b7da1608f3039e	a29864963573d7bb061691ff823b97dd
f0e1f32b93f622ea3ddbf6b55b439812	0cf6ece7453aa814e08cb7c33bd39846
f0e1f32b93f622ea3ddbf6b55b439812	1eef6db16bfc0aaf8904df1503895979
f0e1f32b93f622ea3ddbf6b55b439812	34d8a5e79a59df217c6882ee766c850a
f0e1f32b93f622ea3ddbf6b55b439812	ff7aa8ca226e1b753b0a71d7f0f2e174
f29d276fd930f1ad7687ed7e22929b64	01864d382accf1cdb077e42032b16340
f37ab058561fb6d233b9c2a0b080d4d1	f82c0cf1d80eca5ea2884bbc7bd04269
f4219e8fec02ce146754a5be8a85f246	01864d382accf1cdb077e42032b16340
f4219e8fec02ce146754a5be8a85f246	885ba57d521cd859bacf6f76fb37ef7c
f4f870098db58eeae93742dd2bcaf2b2	1868ffbe3756a1c3f58300f45aa5e1d3
f60ab90d94b9cafe6b32f6a93ee8fcda	1c800aa97116d9afd83204d65d50199a
f644bd92037985f8eb20311bc6d5ed94	17b8dff9566f6c98062ad5811c762f44
f8e7112b86fcd9210dfaf32c00d6d375	bb273189d856ee630d92fbc0274178bb
f953fa7b33e7b6503f4380895bbe41c8	2e607ef3a19cf3de029e2c5882896d33
f953fa7b33e7b6503f4380895bbe41c8	a29864963573d7bb061691ff823b97dd
fa03eb688ad8aa1db593d33dabd89bad	8de5a5b30fc3e013e9b52811fe6f3356
fa03eb688ad8aa1db593d33dabd89bad	a68d5b72c2f98613f511337a59312f78
faabbecd319372311ed0781d17b641d1	2336f976c6d510d2a269a746a7756232
faabbecd319372311ed0781d17b641d1	7a3808eef413b514776a7202fd2cb94f
faabbecd319372311ed0781d17b641d1	8dae638cc517185f1e6f065fcd5e8af3
fb28e62c0e801a787d55d97615e89771	a68d5b72c2f98613f511337a59312f78
fb47f889f2c7c4fee1553d0f817b8aaa	17b8dff9566f6c98062ad5811c762f44
fb47f889f2c7c4fee1553d0f817b8aaa	885ba57d521cd859bacf6f76fb37ef7c
fb8be6409408481ad69166324bdade9c	17b8dff9566f6c98062ad5811c762f44
fb8be6409408481ad69166324bdade9c	a29864963573d7bb061691ff823b97dd
fcd1c1b547d03e760d1defa4d2b98783	4fb2ada7c5440a256ed0e03c967fce74
fd85bfffd5a0667738f6110281b25db8	17b8dff9566f6c98062ad5811c762f44
fd85bfffd5a0667738f6110281b25db8	caac3244eefed8cffee878acae427e28
fdc90583bd7a58b91384dea3d1659cde	04ae76937270105919847d05aee582b4
fdc90583bd7a58b91384dea3d1659cde	dcd00c11302e3b16333943340d6b4a6b
fe228019addf1d561d0123caae8d1e52	36e61931478cf781e59da3b5ae2ee64e
fe5b73c2c2cd2d9278c3835c791289b6	01864d382accf1cdb077e42032b16340
fe5b73c2c2cd2d9278c3835c791289b6	7a3808eef413b514776a7202fd2cb94f
ff578d3db4dc3311b3098c8365d54e6b	7fa69773873856d74f68a6824ca4b691
ff5b48d38ce7d0c47c57555d4783a118	4fb2ada7c5440a256ed0e03c967fce74
ffa7450fd138573d8ae665134bccd02c	17b8dff9566f6c98062ad5811c762f44
2447873ddeeecaa165263091c0cbb22f	7a09fdabda255b02b2283e724071944b
fdcf3cdc04f367257c92382e032b6293	a279b219de7726798fc2497d48bc0402
fdcf3cdc04f367257c92382e032b6293	885ba57d521cd859bacf6f76fb37ef7c
bbddc022ee323e0a2b2d8c67e5cd321f	eaa57a9b4248ce3968e718895e1c2f04
94ca28ea8d99549c2280bcc93f98c853	a68d5b72c2f98613f511337a59312f78
94ca28ea8d99549c2280bcc93f98c853	885ba57d521cd859bacf6f76fb37ef7c
94ca28ea8d99549c2280bcc93f98c853	17b8dff9566f6c98062ad5811c762f44
6d89517dbd1a634b097f81f5bdbb07a2	8a055a3739ca4b38b9c5a188d6295830
eb3bfb5a3ccdd4483aabc307ae236066	eaa57a9b4248ce3968e718895e1c2f04
0ab20b5ad4d15b445ed94fa4eebb18d8	7a3808eef413b514776a7202fd2cb94f
12e93f5fab5f7d16ef37711ef264d282	a29864963573d7bb061691ff823b97dd
33f03dd57f667d41ac77c6baec352a81	bb273189d856ee630d92fbc0274178bb
399033f75fcf47d6736c9c5209222ab8	d5a9c37bc91d6d5d55a3c2e38c3bf97d
399033f75fcf47d6736c9c5209222ab8	0cf6ece7453aa814e08cb7c33bd39846
399033f75fcf47d6736c9c5209222ab8	885ba57d521cd859bacf6f76fb37ef7c
d9bc1db8c13da3a131d853237e1f05b2	17b8dff9566f6c98062ad5811c762f44
d9bc1db8c13da3a131d853237e1f05b2	a29864963573d7bb061691ff823b97dd
d9bc1db8c13da3a131d853237e1f05b2	ea9565886c02dbdc4892412537e607d7
1197a69404ee9475146f3d631de12bde	885ba57d521cd859bacf6f76fb37ef7c
1197a69404ee9475146f3d631de12bde	9c093ec7867ba1df61e27a5943168b90
fdcbfded0aaf369d936a70324b39c978	eaa57a9b4248ce3968e718895e1c2f04
fdcbfded0aaf369d936a70324b39c978	6add228b14f132e14ae9da754ef070c5
754230e2c158107a2e93193c829e9e59	a29864963573d7bb061691ff823b97dd
a29c1c4f0a97173007be3b737e8febcc	17b8dff9566f6c98062ad5811c762f44
4fab532a185610bb854e0946f4def6a4	17b8dff9566f6c98062ad5811c762f44
e25ee917084bdbdc8506b56abef0f351	17b8dff9566f6c98062ad5811c762f44
e6fd7b62a39c109109d33fcd3b5e129d	17b8dff9566f6c98062ad5811c762f44
e6fd7b62a39c109109d33fcd3b5e129d	10a17b42501166d3bf8fbdff7e1d52b6
da29e297c23e7868f1d50ec5a6a4359b	17b8dff9566f6c98062ad5811c762f44
da29e297c23e7868f1d50ec5a6a4359b	a68d5b72c2f98613f511337a59312f78
da29e297c23e7868f1d50ec5a6a4359b	885ba57d521cd859bacf6f76fb37ef7c
96048e254d2e02ba26f53edd271d3f88	17b8dff9566f6c98062ad5811c762f44
c2275e8ac71d308946a63958bc7603a1	a29864963573d7bb061691ff823b97dd
3bcbddf6c114327fc72ea06bcb02f9ef	a29864963573d7bb061691ff823b97dd
3bcbddf6c114327fc72ea06bcb02f9ef	a68d5b72c2f98613f511337a59312f78
dde3e0b0cc344a7b072bbab8c429f4ff	a29864963573d7bb061691ff823b97dd
dde3e0b0cc344a7b072bbab8c429f4ff	a68d5b72c2f98613f511337a59312f78
dde3e0b0cc344a7b072bbab8c429f4ff	17b8dff9566f6c98062ad5811c762f44
b785a5ffad5e7e36ccac25c51d5d8908	a29864963573d7bb061691ff823b97dd
63c0a328ae2bee49789212822f79b83f	0d1830fc8ac21dfabd6f33ab01578c0b
83d15841023cff02eafedb1c87df9b11	10a17b42501166d3bf8fbdff7e1d52b6
f03bde11d261f185cbacfa32c1c6538c	a29864963573d7bb061691ff823b97dd
f03bde11d261f185cbacfa32c1c6538c	17b8dff9566f6c98062ad5811c762f44
f6540bc63be4c0cb21811353c0d24f69	262770cfc76233c4f0d7a1e43a36cbf7
e4f0ad5ef0ac3037084d8a5e3ca1cabc	17b8dff9566f6c98062ad5811c762f44
e4f0ad5ef0ac3037084d8a5e3ca1cabc	a29864963573d7bb061691ff823b97dd
e4f0ad5ef0ac3037084d8a5e3ca1cabc	fd00614e73cb66fd71ab13c970a074d8
ea16d031090828264793e860a00cc995	17b8dff9566f6c98062ad5811c762f44
5eed658c4b7b68a0ecc49205b68d54e7	deb8040131c3f6a3caf6a616b34ac482
a0fb30950d2a150c1d2624716f216316	17b8dff9566f6c98062ad5811c762f44
a0fb30950d2a150c1d2624716f216316	a68d5b72c2f98613f511337a59312f78
4ad6c928711328d1cf0167bc87079a14	1868ffbe3756a1c3f58300f45aa5e1d3
4ad6c928711328d1cf0167bc87079a14	17b8dff9566f6c98062ad5811c762f44
96e3cdb363fe6df2723be5b994ad117a	efe010f3a24895472e65b173e01b969d
c8d551145807972d194691247e7102a2	17b8dff9566f6c98062ad5811c762f44
45b568ce63ea724c415677711b4328a7	17b8dff9566f6c98062ad5811c762f44
c238980432ab6442df9b2c6698c43e47	9713131159f9810e6f5ae73d82633adb
145bd9cf987b6f96fa6f3b3b326303c9	a68d5b72c2f98613f511337a59312f78
39a25b9c88ce401ca54fd7479d1c8b73	a68d5b72c2f98613f511337a59312f78
8cadf0ad04644ce2947bf3aa2817816e	a68d5b72c2f98613f511337a59312f78
85fac49d29a31f1f9a8a18d6b04b9fc9	a68d5b72c2f98613f511337a59312f78
85fac49d29a31f1f9a8a18d6b04b9fc9	a29864963573d7bb061691ff823b97dd
b81ee269be538a500ed057b3222c86a2	17b8dff9566f6c98062ad5811c762f44
cf71a88972b5e06d8913cf53c916e6e4	17b8dff9566f6c98062ad5811c762f44
5518086aebc9159ba7424be0073ce5c9	17b8dff9566f6c98062ad5811c762f44
5518086aebc9159ba7424be0073ce5c9	01864d382accf1cdb077e42032b16340
5518086aebc9159ba7424be0073ce5c9	a68d5b72c2f98613f511337a59312f78
60f28c7011b5e32d220cbaa0e563291b	a68d5b72c2f98613f511337a59312f78
60f28c7011b5e32d220cbaa0e563291b	17b8dff9566f6c98062ad5811c762f44
60f28c7011b5e32d220cbaa0e563291b	885ba57d521cd859bacf6f76fb37ef7c
6eaeee13a99072e69bab1f707b79c56a	a68d5b72c2f98613f511337a59312f78
2c4e2c9948ddac6145e529c2ae7296da	17b8dff9566f6c98062ad5811c762f44
c9af1c425ca093648e919c2e471df3bd	a68d5b72c2f98613f511337a59312f78
0291e38d9a3d398052be0ca52a7b1592	a68d5b72c2f98613f511337a59312f78
0291e38d9a3d398052be0ca52a7b1592	17b8dff9566f6c98062ad5811c762f44
8852173e80d762d62f0bcb379d82ebdb	a68d5b72c2f98613f511337a59312f78
8852173e80d762d62f0bcb379d82ebdb	17b8dff9566f6c98062ad5811c762f44
000f49c98c428aff4734497823d04f45	262770cfc76233c4f0d7a1e43a36cbf7
000f49c98c428aff4734497823d04f45	17b8dff9566f6c98062ad5811c762f44
dea293bdffcfb292b244b6fe92d246dc	a68d5b72c2f98613f511337a59312f78
302ebe0389198972c223f4b72894780a	a29864963573d7bb061691ff823b97dd
ac62ad2816456aa712809bf01327add1	04ae76937270105919847d05aee582b4
470f3f69a2327481d26309dc65656f44	885ba57d521cd859bacf6f76fb37ef7c
470f3f69a2327481d26309dc65656f44	17b8dff9566f6c98062ad5811c762f44
e254616b4a5bd5aaa54f90a3985ed184	17b8dff9566f6c98062ad5811c762f44
e254616b4a5bd5aaa54f90a3985ed184	a68d5b72c2f98613f511337a59312f78
3c5c578b7cf5cc0d23c1730d1d51436a	4fb2ada7c5440a256ed0e03c967fce74
3c5c578b7cf5cc0d23c1730d1d51436a	04ae76937270105919847d05aee582b4
eaeaed2d9f3137518a5c8c7e6733214f	36e61931478cf781e59da3b5ae2ee64e
8ccd65d7f0f028405867991ae3eaeb56	04ae76937270105919847d05aee582b4
8ccd65d7f0f028405867991ae3eaeb56	585f02a68092351a078fc43a21a56564
781acc7e58c9a746d58f6e65ab1e90c4	239401e2c0d502df7c9009439bdb5bd3
e5a674a93987de4a52230105907fffe9	564807fb144a93a857bfda85ab34068d
e5a674a93987de4a52230105907fffe9	a68d5b72c2f98613f511337a59312f78
a2459c5c8a50215716247769c3dea40b	bb273189d856ee630d92fbc0274178bb
e285e4ecb358b92237298f67526beff7	885ba57d521cd859bacf6f76fb37ef7c
e285e4ecb358b92237298f67526beff7	17b8dff9566f6c98062ad5811c762f44
e285e4ecb358b92237298f67526beff7	0cf6ece7453aa814e08cb7c33bd39846
e285e4ecb358b92237298f67526beff7	ff7aa8ca226e1b753b0a71d7f0f2e174
e285e4ecb358b92237298f67526beff7	5bf88dc6f6501943cc5bc4c42c71b36b
d832b654664d104f0fbb9b6674a09a11	1eef6db16bfc0aaf8904df1503895979
2aeb128c6d3eb7e79acb393b50e1cf7b	0cf6ece7453aa814e08cb7c33bd39846
213c449bd4bcfcdb6bffecf55b2c30b4	1eef6db16bfc0aaf8904df1503895979
213c449bd4bcfcdb6bffecf55b2c30b4	9d78e15bf91aef0090e0a37bab153d98
213c449bd4bcfcdb6bffecf55b2c30b4	a46700f6342a2525a9fba12d974d786e
4ea353ae22a1c0d26327638f600aeac8	a46700f6342a2525a9fba12d974d786e
4ea353ae22a1c0d26327638f600aeac8	1eef6db16bfc0aaf8904df1503895979
66244bb43939f81c100f03922cdc3439	4fb2ada7c5440a256ed0e03c967fce74
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: music; Owner: postgres
--

COPY music.events (id_event, event, date_event, id_place) FROM stdin;
8640cd270510da320a9dd71429b95531	NOAF XI	2015-08-28	bb1bac023b4f02a5507f1047970d1aca
9e829f734a90920dd15d3b93134ee270	EMP Persistence Tour 2016	2016-01-22	427a371fadd4cce654dd30c27a36acb0
d3284558d8cda50eb33b5e5ce91da2af	Before we go Farewell Tour 2016	2016-02-11	427a371fadd4cce654dd30c27a36acb0
c5593cbec8087184815492eee880f9a8	Randy Hansen live in Frankfurt	2016-04-26	fd4c04c6fadcc6eafbc12e81374bca85
52b133bfecec2fba79ecf451de3cf3bb	V??lkerball	2016-05-05	657d564cc1dbaf58e2f2135b57d02d99
e872b77ff7ac24acc5fa373ebe9bb492	Molotov	2016-07-25	427a371fadd4cce654dd30c27a36acb0
ec9a23a8132c85ca37af85c69a2743c5	NOAF XII	2016-08-26	bb1bac023b4f02a5507f1047970d1aca
d1832e7b44502c04ec5819ef3085371a	Dia de los muertos Roadshow 2016	2016-11-11	427a371fadd4cce654dd30c27a36acb0
939fec794a3b41bc213c4df0c66c96f5	Jomsviking European Tour 2016	2016-11-17	2a8f2b9aef561f19faad529d927dba17
0e33f8fbbb12367a6e8159a3b096898a	Skindred, Zebrahead	2016-12-09	427a371fadd4cce654dd30c27a36acb0
1fad423d9d1f48b7bd6d31c8d5cb17ed	EMP Persistence Tour 2017	2017-01-24	427a371fadd4cce654dd30c27a36acb0
c8ee19d8e2f21851dc16db65d7b138bc	Kreator, Sepultura, Soilwork, Aborted	2017-02-17	427a371fadd4cce654dd30c27a36acb0
a61b878c2b563f289de2109fa0f42144	Conan	2017-03-08	427a371fadd4cce654dd30c27a36acb0
bbce8e45250a239a252752fac7137e00	In Flames	2017-03-24	38085fa2d02ff7710a42a0c61ab311e2
e1baa5fa38e1e6c824f2011f89475f03	The Popestar Tour 2017	2017-04-09	427a371fadd4cce654dd30c27a36acb0
42c7a1c1e7836f74ced153a27d98cef0	Matapaloz Festival 2017	2017-06-16	d379f693135eefa77bc9732f97fcaaf1
20b7e40ecd659c47ca991e0d420a54eb	Rockfield Open Air 2017	2017-08-18	55ff4adc7d421cf9e05b68d25ee22341
372ca4be7841a47ba693d4de7d220981	NOAF XIII	2017-08-25	bb1bac023b4f02a5507f1047970d1aca
d2a4c05671f768ba487ad365d2a0fb6e	Metallergrillen 2017	2017-09-01	d5c76ce146e0b3f46e69e870e9d48181
5e65cc6b7435c63dac4b2baf17ab5838	Grill' Em All 2017	2017-09-23	29ae00a7e41558eb2ed8c0995a702d7a
084c45f4c0bf86930df25ae1c59b3fe6	The Path of Death 6	2017-10-14	620f9da22d73cc8d5680539a4c87402b
63a722e7e0aa4866721305fab1342530	EMP Persistence Tour 2018	2018-01-23	427a371fadd4cce654dd30c27a36acb0
64896cd59778f32b1c61561a21af6598	Will to power tour 2018	2018-02-06	427a371fadd4cce654dd30c27a36acb0
26a40a3dc89f8b78c61fa31d1137482c	Worldwired Tour 2018	2018-02-16	7786a0fc094d859eb469868003b142db
568177b2430c48380b6d8dab67dbe98c	Warfield / Purify / Sober Truth	2018-02-17	4e637199a58a4ff2ec4b956d06e472e8
85c434b11120b4ba2f116e89843a594e	Heidelberg Deathfest III	2018-03-24	828d35ecd5412f7bc1ba369d5d657f9f
eb2330cf8b87aa13aad89f32d6cfda18	Guido's Super Sweet 16 (30. jubilee)	2018-04-27	8bb89006a86a427f89e49efe7f1635c1
d8f74ab86e77455ffbd398065ee109a8	Slamming Annihilation European Tour 2018	2018-05-21	0b186d7eb0143e60ced4af3380f5faa8
a7fe0b5f5ae6fbfa811d754074e03d95	Grabbenacht Festival 2018	2018-06-01	7adc966f52e671b15ea54075581c862b
fcbfd4ea93701414772acad10ad93a5f	V??lkerball in Mainz	2018-07-27	19a1767aab9e93163ad90f2dfe82ec71
3f15c445cb553524b235b01ab75fe9a6	Ministry	2018-08-06	427a371fadd4cce654dd30c27a36acb0
f10fa26efffb6c69534e7b0f7890272d	Rockfield Open Air 2018	2018-08-17	55ff4adc7d421cf9e05b68d25ee22341
a72c5a8b761c2fc1097f162eeda5d5db	NOAF XIV	2018-08-24	bb1bac023b4f02a5507f1047970d1aca
2a6b51056784227b35e412c444f54359	Metal Embrace Festival XII	2018-09-07	741ae9098af4e50aecf13b0ef08ecc47
e471494f42d963b13f025c0636c43763	Knife, Exorcised Gods, World of Tomorrow, When Plages Collide	2018-09-15	d1ad016a5b257743ef75594c67c52935
663ea93736c204faee5f6c339203be3e	Death is just the beginning	2018-10-18	427a371fadd4cce654dd30c27a36acb0
f68790d8b2f82aad75f0c27be554ee48	The Path of Death 7	2018-10-20	620f9da22d73cc8d5680539a4c87402b
4c90356614158305d8527b80886d2c1e	Rock for Hille Benefiz	2018-10-27	875ec5037fe25fad96113c57da62f9fe
a626f2fb0794eeb25b074b4c43776634	Dia de los muertos Roadshow 2018	2018-11-02	427a371fadd4cce654dd30c27a36acb0
3af7c6d148d216f13f66669acb8d5c59	Debauchery's Balgeroth	2018-11-03	0b186d7eb0143e60ced4af3380f5faa8
f8ead2514f0df3c6e8ec84b992dd6e44	Hell over Europe II	2018-11-24	0b186d7eb0143e60ced4af3380f5faa8
9afc751ca7f2d91d23c453b32fd21864	The modern art of setting ablaze tour	2018-12-08	427a371fadd4cce654dd30c27a36acb0
0aa506a505f1115202f993ee4d650480	MTV's Headbangers Ball Tour 2018	2018-12-11	427a371fadd4cce654dd30c27a36acb0
f5a56d2eb1cd18bf3059cc15519097ea	X-Mass in Hell Festival West Edition 2018	2018-12-15	4751a5b2d9992dca6e462e3b14695284
96a0774b50f0698d1245f287bfe20223	Mot??rblast Play Mot??rhead	2018-12-27	c6e9ff60da2342ba2a0ce4d9b6fc6ff1
8224efe45b1d8a1ebc0b9fb0a5405ac6	EMP Persistence Tour 2019	2019-01-24	427a371fadd4cce654dd30c27a36acb0
0e4e0056244fb82f89e66904ad62fdaf	The Inmost Light Tatoo 2019	2019-02-01	427a371fadd4cce654dd30c27a36acb0
9418ebabb93c5c1f47a05666913ec6e4	Amorphis & Soilwork	2019-02-13	427a371fadd4cce654dd30c27a36acb0
cc4617b9ce3c2eee5d1e566eb2fbb1f6	Aversions Crown | Psycroptic	2019-02-21	427a371fadd4cce654dd30c27a36acb0
1ea2f5c46c57c12dea2fed56cb87566f	1. Mainzer Rock & Metal Fastnachts-Party	2019-03-02	620f9da22d73cc8d5680539a4c87402b
1104831a0d0fe7d2a6a4198c781e0e0d	Dust Bolt	2019-03-07	427a371fadd4cce654dd30c27a36acb0
7e2e7fa5ce040664bf7aaaef1cebd897	Rock-N-Pop Youngsters 2019	2019-03-15	620f9da22d73cc8d5680539a4c87402b
a122cd22f946f0c229745d88d89b05bd	Deserted Fear / Carnation / Hierophant	2019-03-22	427a371fadd4cce654dd30c27a36acb0
633f06bd0bd191373d667af54af0939b	Heidelberg Deathfest IV	2019-03-23	828d35ecd5412f7bc1ba369d5d657f9f
d1ee83d5951b1668e95b22446c38ba1c	Light to the blind, Slaughterra, All its Grace	2019-03-29	620f9da22d73cc8d5680539a4c87402b
abefb7041d2488eadeedba9a0829b753	Taunus Metal Festival XI	2019-04-12	1e9e26a0456c1694d069e119dae54240
a2cc2bc245b90654e721d7040c028647	Ektomorf - The legion of fury tour 2019	2019-04-25	0b186d7eb0143e60ced4af3380f5faa8
c150d400f383afb8e8427813549a82d3	Guido's sassy 17 (30th edition)	2019-04-26	8bb89006a86a427f89e49efe7f1635c1
189f11691712600d4e1b0bdb4122e8aa	Metal Club Odinwald meets Ultimate Ruination Tour	2019-04-27	50bd324043e0b113bea1b5aa0422806f
488af8bdc554488b6c8854fae6ae8610	Downfall of Mankind Tour 2019	2019-05-07	4e592038a4c7b6cdc3e7b92d98867506
62f7101086340682e5bc58a86976cfb5	Darkness approaching	2019-05-10	620f9da22d73cc8d5680539a4c87402b
7126a50ce66fe18b84a7bfb3defea15f	Rockbahnhof 2019	2019-05-18	bb1bac023b4f02a5507f1047970d1aca
00f269da8a1eee6c08cebcc093968ee1	Grabbenacht Festival 2019	2019-05-30	7adc966f52e671b15ea54075581c862b
d45cf5e6b7af0cee99b37f15b13360ed	28. Wave-Gotik-Treffen	2019-06-08	b67af931a5d0322adc7d56846dca86dc
0dcd062f5beffeaae2efae21ef9f3755	Cannibal Corpse, European Summer Tour 2019	2019-06-30	c6e9ff60da2342ba2a0ce4d9b6fc6ff1
dae84dc2587a374c667d0ba291f33481	Rockharz Open Air 2019	2019-07-03	3b0409f1b5830369aac22e3c5b9b9815
53812183e083ed8a87818371d6b3dbfb	Rockfield Open Air 2019	2019-08-09	55ff4adc7d421cf9e05b68d25ee22341
5e45d87cab8e0b30fba4603b4821bfcd	European Tour Summer 2019	2019-08-13	427a371fadd4cce654dd30c27a36acb0
ca69aebb5919e75661d929c1fbd39582	NOAF XV	2019-08-23	bb1bac023b4f02a5507f1047970d1aca
12e7b1918420daf69b976a5949f9ba85	Worldwired Tour 2019	2019-08-25	21760b1bbe36b4dae8fa9e0c274f76bf
6b09e6ae26a0d03456b17df4c0964a2f	Metal Embrace Festival XIII	2019-09-06	741ae9098af4e50aecf13b0ef08ecc47
ff3bed6eb88bb82b3a77ddaf50933689	Doom over Mainz	2019-09-21	620f9da22d73cc8d5680539a4c87402b
c9a70f42ce4dcd82a99ed83a5117b890	Where Owls know my name EU|UK Tour 2019	2019-09-22	427a371fadd4cce654dd30c27a36acb0
0a85beacde1a467e23452f40b4710030	Way of Darkness 2019	2019-10-04	beeb45e34fe94369bed94ce75eb1e841
d5cd210a82be3dd1a7879b83ba5657c0	15 Years New Evil Music, Festival	2019-10-12	4751a5b2d9992dca6e462e3b14695284
c3b4e4db5f94fac6979eb07371836e81	Heavy metal gegen Mikroplastik	2019-10-19	8bb89006a86a427f89e49efe7f1635c1
00da417154f2da39e79c9dcf4d7502fa	Prayer Of Annihilation Tour 2019	2019-10-24	4751a5b2d9992dca6e462e3b14695284
d8f60019c8e6cdbb84839791fd989d81	The Path of Death 8	2019-10-26	620f9da22d73cc8d5680539a4c87402b
a7ea7b6c1894204987ce4694c1febe03	Halloween Party 2019	2019-10-31	8bb89006a86a427f89e49efe7f1635c1
f861455af8364fc3fe01aef3fc597905	Sons of Rebellion Tour 2019	2019-11-01	4751a5b2d9992dca6e462e3b14695284
8368e0fd31972c67de1117fb0fe12268	Pagan Metal Festival	2019-11-03	0b186d7eb0143e60ced4af3380f5faa8
b6aaab867e3c1c7bfe215d7db747e5d9	Hell over Aschaffenburg	2019-11-30	858d53d9bd193393481e4e8b24d10bba
43bcb284a3d1a0eea2c7923d45b7f14e	Berserker World Tour 2019	2019-12-03	44e48d95c27db0d3558a072c139d2761
20cf9df7281c50060aaf023e04fd5082	Winter Hostilities 2019-Tour	2019-12-04	427a371fadd4cce654dd30c27a36acb0
060fd8422f03df6eca94da7605b3a9cd	MTV's Headbangers Ball Tour 2019	2019-12-14	427a371fadd4cce654dd30c27a36acb0
6d5c464f0c139d97e715c51b43983695	To Drink from the Night Itself, Europe 2019	2019-12-15	427a371fadd4cce654dd30c27a36acb0
f8549f73852c778caa3e9c09558739f2	Eis und Nacht Tour 2020	2020-01-24	0b186d7eb0143e60ced4af3380f5faa8
553a00f0c40ce1b1107f833da69988e4	We Are Not Your Kind World Tour	2020-01-29	e74b09ddc9ecbc635ae3ce58a4cddd59
be95780f2b4fba1a76846b716e69ed6d	Friendship & Love Metal Fest	2020-02-15	41b6f7fdc3453cc5f989c347d9b4b674
06e5f3d0d817c436d351a9cf1bf94dfa	The Gidim European Tour 2020	2020-03-05	427a371fadd4cce654dd30c27a36acb0
dcda9434b422f9aa793f0a8874922306	A Tribute to ACDC 2020	2020-03-07	59c2a4862605f1128b334896c17cab7b
4bc4f9db3d901e8efe90f60d85a0420d	Descend into Madness Tour 2020	2020-03-11	427a371fadd4cce654dd30c27a36acb0
d0f1ffdb2d3a20a41f9c0f10df3b9386	S??dpfalz Metalfest	2020-09-25	875ec5037fe25fad96113c57da62f9fe
73d6ec35ad0e4ef8f213ba89d8bfd7d7	New live rituals a COVID proof celebration of audial darkness	2021-07-23	2b18765ced0c329ecd1f1663925e8342
441306dd21b61d9a52e04b9e177cc9b5	Jubil??umswoche 25 Jahre Hexenhaus	2021-07-31	012d8da36e8518d229988fe061f3c376
13afebb96e2d2d27345bd3b1fefc4db0	Crossplane & H??ngerb??nd	2021-08-07	f3c1ffc50f4f8d0a857533164e8da867
dd50d5dcc02ea12c31e0ff495891dc22	"Still Cyco Punk" World Wide Tour 2018	2018-11-04	c6e9ff60da2342ba2a0ce4d9b6fc6ff1
3c61b014201d6f62468d72d0363f7725	Crisix, Insanity Alert	2021-09-16	0b186d7eb0143e60ced4af3380f5faa8
f3603438cf79ee848cb2f5e4a5884663	Alexander the Great in Exil	2021-09-11	14b82c93c42422209e5b5aad5b7b772e
a71ac13634cd0b6d26e52d11c76f0a63	Warfield/Torment of Souls/Redgrin	2021-10-02	3611a0c17388412df8e42cf1858d5e99
8d821ce4aedb7300e067cfa9eb7f1eee	The Path of Death 9	2021-11-13	620f9da22d73cc8d5680539a4c87402b
fce1fb772d7bd71211bb915625ac11af	World needs mosh (Wiesbaden)	2021-11-19	427a371fadd4cce654dd30c27a36acb0
95f89582ba9dcfbed475ebb3c06162db	World needs mosh (Bonn)	2021-11-21	99d75d9948711c04161016c0d2280dd9
9f1a399c301132b273f595b1cfc5e99d	SARCOFAGO TRIBUTE (Fabio Jhasko)	2021-11-25	0b186d7eb0143e60ced4af3380f5faa8
23fcfcbd4fa686b213960a04f49856f4	Dark Zodiak + Mortal Peril	2021-11-27	2898437c2420ae271ae3310552ad6d70
54bf7e97edddf051b2a98b21b6d47e6a	Slaughterra - Darmstadt	2022-03-05	2898437c2420ae271ae3310552ad6d70
bb378a3687cc64953bf36ccea6eb5a27	Warfield - Caf?? Central	2022-02-05	0b186d7eb0143e60ced4af3380f5faa8
46ffa374af00ed2b76c1cfaa98b76e90	Heidelberg Deathfest V	2022-03-19	828d35ecd5412f7bc1ba369d5d657f9f
0cd1c230352e99227f43acc46129d6b4	Morbidfest	2022-04-19	0b186d7eb0143e60ced4af3380f5faa8
6f14a4e8ecdf87e02d77cec09b6c98b9	50 Jahre Doktor Holzbein	2022-04-23	14b82c93c42422209e5b5aad5b7b772e
808e3291422cea1b35c76af1b5ba5326	Doomsday Album Release Tour	2022-04-28	427a371fadd4cce654dd30c27a36acb0
20970f44b43a10d7282a77eda20866e2	Necro Sapiens Tour 2022	2022-05-05	427a371fadd4cce654dd30c27a36acb0
9feb9a9930d633ef18e1dae581b65327	Horresque & Guests	2022-05-13	620f9da22d73cc8d5680539a4c87402b
8342e65069254a6fd6d2bbc87aff8192	Braincrusher in Hell 2020	2022-05-20	871568e58a911610979cadc2c1e94122
320951dccf4030808c979375af8356b6	Wild Boar Wars III	2021-08-28	fd4c04c6fadcc6eafbc12e81374bca85
7712d7dceef5a521b4a554c431752979	29. Wave-Gotik-Treffen	2022-06-05	b67af931a5d0322adc7d56846dca86dc
6118dc6a9a96e892fa5bbaac3ccb6d99	Download Germany	2022-06-24	d379f693135eefa77bc9732f97fcaaf1
9c697f7def422e3f6f885d3ec9741603	Grill' Em All 2022	2022-07-02	29ae00a7e41558eb2ed8c0995a702d7a
b1e4aa22275a6a4b3213b44fc342f9fe	Sepultura - Quadra Summer Tour - Europe 2022	2022-07-05	6d998a5f2c8b461a654f7f9e34ab4368
31c3824b57ad0919df18a79978c701e9	Post Covid European Summer Madness 2022	2022-07-19	427a371fadd4cce654dd30c27a36acb0
\.


--
-- Data for Name: generes; Type: TABLE DATA; Schema: music; Owner: postgres
--

COPY music.generes (id_genere, genere) FROM stdin;
17b8dff9566f6c98062ad5811c762f44	Death Metal
a29864963573d7bb061691ff823b97dd	Thrash Metal
a68d5b72c2f98613f511337a59312f78	Black Metal
04ae76937270105919847d05aee582b4	Heavy Metal
7fa69773873856d74f68a6824ca4b691	Brutal Death Metal
01864d382accf1cdb077e42032b16340	Melodic Death Metal
d5a9c37bc91d6d5d55a3c2e38c3bf97d	Groove Metal
7a3808eef413b514776a7202fd2cb94f	Metalcore
10a17b42501166d3bf8fbdff7e1d52b6	Grindcore
885ba57d521cd859bacf6f76fb37ef7c	Doom Metal
dcd00c11302e3b16333943340d6b4a6b	Hard Rock
caac3244eefed8cffee878acae427e28	Deathcore
585f02a68092351a078fc43a21a56564	Speed Metal
4fb2ada7c5440a256ed0e03c967fce74	Power Metal
2336f976c6d510d2a269a746a7756232	Hardcore Punk
1c800aa97116d9afd83204d65d50199a	Hardcore
ea9565886c02dbdc4892412537e607d7	Sludge Metal
2e607ef3a19cf3de029e2c5882896d33	Crossover
2df929d9b6150c082888b66e8129ee3f	Technical Death Metal
bb273189d856ee630d92fbc0274178bb	Alternative Metal
02d3190ce0f08f32be33da6cc8ec8df8	Nu Metal
4cfbb125e9878528bab91d12421134d8	Rock
eaa57a9b4248ce3968e718895e1c2f04	Metal
ff7aa8ca226e1b753b0a71d7f0f2e174	Alternative Rock
924ae2289369a9c1d279d1d59088be64	Slamming Brutal Death Metal
8c42e2739ed83a54e5b2781b504c92de	Folk Metal
f0095594f17b3793be8291117582f96b	Post-Hardcore
0cf6ece7453aa814e08cb7c33bd39846	Gothic Metal
f41da0c65a8fa3690e6a6877e7112afb	Progressive Metal
deb8040131c3f6a3caf6a616b34ac482	Goregrind
60e1fa5bfa060b5fff1db1ca1bae4f99	Post-Metal
7349da19c2ad6654280ecf64ce42b837	Oi!
ef5131009b7ced0b35ea49c8c7690cef	Punk Rock
34d8a5e79a59df217c6882ee766c850a	Industrial Metal
5bf88dc6f6501943cc5bc4c42c71b36b	Punk
9c093ec7867ba1df61e27a5943168b90	Gothic Rock
e8376ca6a0ac30b2ad0d64de6061adab	Viking Metal
d5d0458ada103152d94ff3828bf33909	Progressive Rock
36e61931478cf781e59da3b5ae2ee64e	Melodic Heavy Metal
2a78330cc0de19f12ae9c7de65b9d5d5	Psychedelic Rock
1396a3913454b8016ddf671d02e861b1	Stoner Rock
97a6395e2906e8f41d27e53a40aebae4	Symphonic Death Metal
de62af4f3af4adf9e8c8791071ddafe3	Symphonic Black Metal
6add228b14f132e14ae9da754ef070c5	Rock'n'Roll
239401e2c0d502df7c9009439bdb5bd3	Post-Black Metal
6de7f9aa9c912bf8c81a9ce2bfc062bd	Heavy Hardcore
2bd0f5e2048d09734470145332ecdd24	Epic Doom Metal
1d67aeafcd3b898e05a75da0fdc01365	Crust Metal
ed8e37bad13d76c6dbeb58152440b41e	Ambient
65d1fb3d4d28880c964b985cf335e04c	Stoner Metal
bbc90d6701da0aa2bf7f6f2acb79e18c	Blues Rock
1868ffbe3756a1c3f58300f45aa5e1d3	Blackened Death Metal
8dae638cc517185f1e6f065fcd5e8af3	Melodic Hardcore
a279b219de7726798fc2497d48bc0402	Southern Metal
b86219c2df5a0d889f490f88ff22e228	Avant-garde Black Metal
72616c6de7633d9ac97165fc7887fa3a	Rap Rock
781f547374aef3a99c113ad5a9c12981	Pornogrind
4c4f4d32429ac8424cb110b4117036e4	Beatdown
0138eefa704205fd48d98528ddcdd5bc	Melodic Thrash Metal
02c4d46b0568d199466ef1baa339adc8	Pop Punk
c1bfb800f95ae493952b6db9eb4f0209	Space Rock
1302a3937910e1487d44cec8f9a09660	Rap Metal
1eef6db16bfc0aaf8904df1503895979	Dark Rock
c08ed51a7772c1f8352ad69071187515	Post-Grunge
e7faf05839e2f549fb3455df7327942b	Ska Punk
2e9dfd2e07792b56179212f5b8f473e6	Funk Rock
8a055a3739ca4b38b9c5a188d6295830	Melodic Power Metal
262770cfc76233c4f0d7a1e43a36cbf7	Melodic Black Metal
f82c0cf1d80eca5ea2884bbc7bd04269	Medieval Rock
ba60b529061c0af9afe655b44957e41b	Extreme Gothic Metal
fc8e55855e2f474c28507e4db7ba5f13	Mathcore
d3fcef9d7f88d2a12ea460c604731cd5	German Punk
ad49b27a742fb199ab722bce67e9c7b2	Stoner Doom
4428b837e98e3cc023fc5cd583b28b20	Atmospheric Sludge Metal
5cbdaf6af370a627c84c43743e99e016	Modern Metal
bfd67ea5a2f5557126b299e33a435ab3	Comedy Rap
dfda7d5357bc0afc43a89e8ac992216f	Tribute to Rammstein
a379c6c3bf4b1a401ce748b34729389a	Viking Black Metal
7ac5b6239ee196614c19db6965c67b31	Post-Rock
f79873ac4ff0e556619b15d82f6da52c	Post-Punk
b6a0263862e208f05258353f86fa3318	Epic Power Metal
fd00614e73cb66fd71ab13c970a074d8	Progressive Death Metal
cb6ef856481bc776bba38fbf15b8b3fb	Pagan Black Metal
f224a37b854811cb14412ceeca43a6ad	Shoegaze
268a3b877b5f3694d5d1964c654ca91c	Irish Folk Punk
7886613ffb324e4e0065f25868545a63	Melodic Groove Metal
763a34aaa76475a926827873753d534f	Ambient Post-Black Metal
17095255b1df76ab27dd48f29b215a5f	Tribute to Rage against the Machine
d31813e8ef36490c57d4977e637efbd4	Street Punk
d93cf30d3eb53125668057b982b433a3	Technical Deathcore
0849fb9eb585f2c20b427a99f1231e40	Medieval Metal
887f0b9675f70bc312e17c93f248b5aa	Electronic Metal
7a09fdabda255b02b2283e724071944b	Black'n'Roll
9ba0204bc48d4b8721344dd83b832afe	Tribute to Mot??rhead
e6218d584a501be9b1c36ac5ed13f2db	Beatdown Hardcore
94876c8f843fa0641ed7bdf6562bdbcf	Tribute to Jimi Hendrix
273112316e7fab5a848516666e3a57d1	Folk
8472603ee3d6dea8e274608e9cbebb6b	Occult Rock
65805a3772889203be8908bb44d964b3	Stoner
57a1aaebe3e5e271aca272988c802651	Horror Punk
b45e0862060b7535e176f48d3e0b89f3	Electronic Body Music
6fa3bbbff822349fee0eaf8cd78c0623	Rapcore
ff3a5da5aa221f7e16361efcccf4cbaa	Alternativ Grunge
ad6296818a1cb902ac5d1a3950e79dbe	Comedy Rock
4895247ad195629fecd388b047a739b4	Industrial Rock
320094e3f180ee372243f1161e9adadc	Pop(p)core
5b412998332f677ddcc911605985ee3b	Tribute to ACDC
b7628553175256a081199e493d97bd3b	Fast Rock'n'Roll
93cce11930403f5b3ce8938a2bde5efa	Pagan Metal
4b3bb0b44a6aa876b9e125a2c2a5d6a2	Extreme Metal
fad6ee4f3b0aded7d0974703e35ae032	Trancecore
2894c332092204f7389275e1359f8e9b	Progressive Thrash Metal
fbe238aca6c496dcd05fb8d6d98f275b	Symphonic Melodic Death Metal
fa20a7164233ec73db640970dae420cf	Symphonic Power Metal
cbfeef2f0e2cd992e0ea65924a0f28a1	Avant-garde Metal
e22aa8f4c79b6c4bbeb6bcc7f4e1eb26	Slam Metal
8bbab0ae4d00ad9ffee6cddaf9338584	Hip Hop
4144b216bf706803a5f17d7d0a9cf4a3	Goth'n'Roll
6fb9bf02fc5d663c1de8c117382bed0b	Agressive Rock
bca74411b74f01449c61b29131bc545e	Proto Metal
f633e7b30932bbf60ed87e8ebc26839d	Tribute to Bathory
b7d08853c905c8cd1467f7bdf0dc176f	Tribute to Black Sabbath
2d4b3247824e58c3c9af547cce7c2c8f	Reggae Rock
eb182befdeccf17696b666b32eb5a313	Blackened Thrash Metal
1e612d6c48bc9652afeb616536fced51	Metal Covers
c3ee1962dffaa352386a05e845ab9d0d	Hard Pop
a178914dea39e23c117e164b05b43995	Drone
c5405146cd45f9d9b4f02406c35315a8	Atmospheric Post-Hardcore
64ec11b17b6f822930f9deb757fa59e8	Mariachi Punk
3770d5a677c09a444a026dc7434bff36	Progressive Metalcore
ecbff10e148109728d5ebce3341bb85e	Death'n'Roll
836ea59914cc7a8e81ee0dd63f7c21c1	Melodic Metalcore
ad38eede5e5edecd3903f1701acecf8e	Epic Metal
303d6389f4089fe9a87559515b84156d	Symphonic Metal
8de5a5b30fc3e013e9b52811fe6f3356	Epic Heavy Metal
0d1830fc8ac21dfabd6f33ab01578c0b	Thrashing Deathgrind
efe010f3a24895472e65b173e01b969d	Experimental Metal
9713131159f9810e6f5ae73d82633adb	Atmospheric Black Metal
564807fb144a93a857bfda85ab34068d	Melodic Gothic Metal
a46700f6342a2525a9fba12d974d786e	Neue Deutsche H??rte
9d78e15bf91aef0090e0a37bab153d98	Dark Metal
\.


--
-- Name: countries countries_country_key; Type: CONSTRAINT; Schema: geo; Owner: postgres
--

ALTER TABLE ONLY geo.countries
    ADD CONSTRAINT countries_country_key UNIQUE (country);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: geo; Owner: postgres
--

ALTER TABLE ONLY geo.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id_country);


--
-- Name: places places_pkey; Type: CONSTRAINT; Schema: geo; Owner: postgres
--

ALTER TABLE ONLY geo.places
    ADD CONSTRAINT places_pkey PRIMARY KEY (id_place);


--
-- Name: places places_place_key; Type: CONSTRAINT; Schema: geo; Owner: postgres
--

ALTER TABLE ONLY geo.places
    ADD CONSTRAINT places_place_key UNIQUE (place);


--
-- Name: bands bands_band_key; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands
    ADD CONSTRAINT bands_band_key UNIQUE (band);


--
-- Name: bands_countries bands_countries_pkey; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_countries
    ADD CONSTRAINT bands_countries_pkey PRIMARY KEY (id_band, id_country);


--
-- Name: bands_events bands_events_pkey; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_events
    ADD CONSTRAINT bands_events_pkey PRIMARY KEY (id_band, id_event);


--
-- Name: bands_generes bands_generes_pkey; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_generes
    ADD CONSTRAINT bands_generes_pkey PRIMARY KEY (id_band, id_genere);


--
-- Name: bands bands_pkey; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands
    ADD CONSTRAINT bands_pkey PRIMARY KEY (id_band);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id_event);


--
-- Name: generes generes_genere_key; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.generes
    ADD CONSTRAINT generes_genere_key UNIQUE (genere);


--
-- Name: generes generes_pkey; Type: CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.generes
    ADD CONSTRAINT generes_pkey PRIMARY KEY (id_genere);


--
-- Name: bands_countries bands_countries_id_band_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_countries
    ADD CONSTRAINT bands_countries_id_band_fkey FOREIGN KEY (id_band) REFERENCES music.bands(id_band);


--
-- Name: bands_countries bands_countries_id_country_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_countries
    ADD CONSTRAINT bands_countries_id_country_fkey FOREIGN KEY (id_country) REFERENCES geo.countries(id_country);


--
-- Name: bands_events bands_events_id_band_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_events
    ADD CONSTRAINT bands_events_id_band_fkey FOREIGN KEY (id_band) REFERENCES music.bands(id_band);


--
-- Name: bands_events bands_events_id_event_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_events
    ADD CONSTRAINT bands_events_id_event_fkey FOREIGN KEY (id_event) REFERENCES music.events(id_event);


--
-- Name: bands_generes bands_generes_id_band_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_generes
    ADD CONSTRAINT bands_generes_id_band_fkey FOREIGN KEY (id_band) REFERENCES music.bands(id_band);


--
-- Name: bands_generes bands_generes_id_genere_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.bands_generes
    ADD CONSTRAINT bands_generes_id_genere_fkey FOREIGN KEY (id_genere) REFERENCES music.generes(id_genere);


--
-- Name: events events_id_place_fkey; Type: FK CONSTRAINT; Schema: music; Owner: postgres
--

ALTER TABLE ONLY music.events
    ADD CONSTRAINT events_id_place_fkey FOREIGN KEY (id_place) REFERENCES geo.places(id_place);


--
-- Name: mv_musical_info; Type: MATERIALIZED VIEW DATA; Schema: music; Owner: postgres
--

REFRESH MATERIALIZED VIEW music.mv_musical_info;


--
-- PostgreSQL database dump complete
--

