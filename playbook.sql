--
-- PostgreSQL database dump for Render link
--

\restrict nYro6VNvMoKpwosz3tYkDofuhPyiOMDUPyfUqUBJ1O2dxYtY3LCWVNtkbhK4MAt

-- Dumped from database version 16.14 (Homebrew)
-- Dumped by pg_dump version 16.14 (Homebrew)

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
-- Name: calc_score_delta(); Type: FUNCTION; Schema: public; Owner: milishah
--

CREATE FUNCTION public.calc_score_delta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    new_score NUMERIC(5,2);
    old_score NUMERIC(5,2);
BEGIN
    -- get new score created by article
    SELECT score
    INTO new_score
    FROM reform_scores
    WHERE state_id = NEW.state_id AND score_id = NEW.score_id;

    -- get old score (most recent one in reform_scores)
    SELECT score
    INTO old_score
    FROM reform_scores
    WHERE state_id = NEW.state_id
        AND score_id <> NEW.score_id
        AND scored_at < (
            SELECT scored_at
            FROM reform_scores
            WHERE score_id = NEW.score_id
        )
    ORDER BY scored_at DESC, score_id DESC
    LIMIT 1;

    -- if no prev score exists delta = new_score
    IF old_score IS NULL THEN
        NEW.score_delta := new_score;
    ELSE
        NEW.score_delta := new_score - old_score;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.calc_score_delta() OWNER TO milishah;

--
-- Name: keep_latest_3_reform_scores(); Type: FUNCTION; Schema: public; Owner: milishah
--

CREATE FUNCTION public.keep_latest_3_reform_scores() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM reform_scores
    WHERE score_id IN (
        SELECT score_id
        FROM reform_scores
        WHERE state_id = NEW.state_id
        ORDER BY scored_at DESC, score_id DESC
        OFFSET 3
    );

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.keep_latest_3_reform_scores() OWNER TO milishah;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action_pathways; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.action_pathways (
    pathway_id integer NOT NULL,
    state_id integer NOT NULL,
    category_id integer,
    title character varying(200) NOT NULL,
    path_description text,
    path_status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    started_at date,
    resolved_at date,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT action_pathways_path_status_check CHECK (((path_status)::text = ANY ((ARRAY['active'::character varying, 'pending'::character varying, 'passed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.action_pathways OWNER TO milishah;

--
-- Name: action_pathways_pathway_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.action_pathways_pathway_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_pathways_pathway_id_seq OWNER TO milishah;

--
-- Name: action_pathways_pathway_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.action_pathways_pathway_id_seq OWNED BY public.action_pathways.pathway_id;


--
-- Name: category_scores; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.category_scores (
    cat_score_id integer NOT NULL,
    score_id integer NOT NULL,
    category_id integer NOT NULL,
    score numeric(5,2),
    notes text
);


ALTER TABLE public.category_scores OWNER TO milishah;

--
-- Name: category_scores_cat_score_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.category_scores_cat_score_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.category_scores_cat_score_id_seq OWNER TO milishah;

--
-- Name: category_scores_cat_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.category_scores_cat_score_id_seq OWNED BY public.category_scores.cat_score_id;


--
-- Name: category_variable_values; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.category_variable_values (
    value_id integer NOT NULL,
    var_value numeric(5,2),
    score_id integer NOT NULL,
    var_id integer NOT NULL,
    no_score_reason text
);


ALTER TABLE public.category_variable_values OWNER TO milishah;

--
-- Name: category_variable_values_value_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.category_variable_values_value_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.category_variable_values_value_id_seq OWNER TO milishah;

--
-- Name: category_variable_values_value_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.category_variable_values_value_id_seq OWNED BY public.category_variable_values.value_id;


--
-- Name: news_articles; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.news_articles (
    article_id integer NOT NULL,
    headline character varying(500) NOT NULL,
    summary text,
    source_name character varying(200),
    source_url text,
    published_at timestamp with time zone NOT NULL,
    is_national boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.news_articles OWNER TO milishah;

--
-- Name: news_articles_article_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.news_articles_article_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_articles_article_id_seq OWNER TO milishah;

--
-- Name: news_articles_article_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.news_articles_article_id_seq OWNED BY public.news_articles.article_id;


--
-- Name: news_state_updates; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.news_state_updates (
    article_id integer NOT NULL,
    state_id integer NOT NULL,
    score_id integer NOT NULL,
    score_delta numeric(5,2)
);


ALTER TABLE public.news_state_updates OWNER TO milishah;

--
-- Name: reform_categories; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.reform_categories (
    category_id integer NOT NULL,
    category character varying(100) NOT NULL,
    cat_description text,
    cat_weight numeric(5,2)
);


ALTER TABLE public.reform_categories OWNER TO milishah;

--
-- Name: reform_categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.reform_categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reform_categories_category_id_seq OWNER TO milishah;

--
-- Name: reform_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.reform_categories_category_id_seq OWNED BY public.reform_categories.category_id;


--
-- Name: reform_category_variables; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.reform_category_variables (
    var_id integer NOT NULL,
    var_name character varying(500) NOT NULL,
    var_description text,
    category_id integer NOT NULL
);


ALTER TABLE public.reform_category_variables OWNER TO milishah;

--
-- Name: reform_category_variables_var_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.reform_category_variables_var_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reform_category_variables_var_id_seq OWNER TO milishah;

--
-- Name: reform_category_variables_var_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.reform_category_variables_var_id_seq OWNED BY public.reform_category_variables.var_id;


--
-- Name: reform_scores; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.reform_scores (
    score_id integer NOT NULL,
    state_id integer NOT NULL,
    scored_at timestamp with time zone DEFAULT now() NOT NULL,
    score numeric(5,2) NOT NULL,
    grade character varying(2),
    CONSTRAINT reform_scores_grade_check CHECK (((grade)::text = ANY ((ARRAY['A+'::character varying, 'A'::character varying, 'A-'::character varying, 'B+'::character varying, 'B'::character varying, 'B-'::character varying, 'C+'::character varying, 'C'::character varying, 'C-'::character varying, 'D+'::character varying, 'D'::character varying, 'D-'::character varying, 'F'::character varying])::text[])))
);


ALTER TABLE public.reform_scores OWNER TO milishah;

--
-- Name: reform_scores_score_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.reform_scores_score_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reform_scores_score_id_seq OWNER TO milishah;

--
-- Name: reform_scores_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.reform_scores_score_id_seq OWNED BY public.reform_scores.score_id;


--
-- Name: states; Type: TABLE; Schema: public; Owner: milishah
--

CREATE TABLE public.states (
    state_id integer NOT NULL,
    state_name character varying(100) NOT NULL,
    abbreviation character(2) NOT NULL,
    electoral_votes integer NOT NULL
);


ALTER TABLE public.states OWNER TO milishah;

--
-- Name: states_state_id_seq; Type: SEQUENCE; Schema: public; Owner: milishah
--

CREATE SEQUENCE public.states_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.states_state_id_seq OWNER TO milishah;

--
-- Name: states_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: milishah
--

ALTER SEQUENCE public.states_state_id_seq OWNED BY public.states.state_id;


--
-- Name: action_pathways pathway_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.action_pathways ALTER COLUMN pathway_id SET DEFAULT nextval('public.action_pathways_pathway_id_seq'::regclass);


--
-- Name: category_scores cat_score_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_scores ALTER COLUMN cat_score_id SET DEFAULT nextval('public.category_scores_cat_score_id_seq'::regclass);


--
-- Name: category_variable_values value_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_variable_values ALTER COLUMN value_id SET DEFAULT nextval('public.category_variable_values_value_id_seq'::regclass);


--
-- Name: news_articles article_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_articles ALTER COLUMN article_id SET DEFAULT nextval('public.news_articles_article_id_seq'::regclass);


--
-- Name: reform_categories category_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_categories ALTER COLUMN category_id SET DEFAULT nextval('public.reform_categories_category_id_seq'::regclass);


--
-- Name: reform_category_variables var_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_category_variables ALTER COLUMN var_id SET DEFAULT nextval('public.reform_category_variables_var_id_seq'::regclass);


--
-- Name: reform_scores score_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_scores ALTER COLUMN score_id SET DEFAULT nextval('public.reform_scores_score_id_seq'::regclass);


--
-- Name: states state_id; Type: DEFAULT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.states ALTER COLUMN state_id SET DEFAULT nextval('public.states_state_id_seq'::regclass);


--
-- Data for Name: action_pathways; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.action_pathways (pathway_id, state_id, category_id, title, path_description, path_status, started_at, resolved_at, created_at) FROM stdin;
1	43	1	Strengthen Campaign Finance Transparency	Require clearer disclosure of campaign contributions and independent expenditures.	active	2026-06-14	\N	2026-07-14 11:37:38.71932-04
2	49	5	Create Independent Redistricting Commission	Establish an independent process for drawing congressional and legislative districts.	pending	2026-06-29	\N	2026-07-14 11:37:38.71932-04
\.


--
-- Data for Name: category_scores; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.category_scores (cat_score_id, score_id, category_id, score, notes) FROM stdin;
1	1	7	91.20	\N
2	1	6	83.30	\N
3	1	5	56.50	\N
4	1	4	79.40	\N
5	1	3	67.20	\N
6	1	2	\N	\N
7	1	1	69.70	\N
8	2	7	92.20	\N
9	2	6	100.00	\N
10	2	5	57.20	\N
11	2	4	63.50	\N
12	2	3	41.50	\N
13	2	2	\N	\N
14	2	1	69.40	\N
15	3	7	93.60	\N
16	3	6	83.30	\N
17	3	5	60.00	\N
18	3	4	78.60	\N
19	3	3	53.90	\N
20	3	2	\N	\N
21	3	1	60.50	\N
22	4	7	96.60	\N
23	4	6	83.30	\N
24	4	5	21.60	\N
25	4	4	72.40	\N
26	4	3	69.10	\N
27	4	2	\N	\N
28	4	1	76.90	\N
29	5	7	99.10	\N
30	5	6	50.00	\N
31	5	5	46.50	\N
32	5	4	62.50	\N
33	5	3	73.80	\N
34	5	2	\N	\N
35	5	1	78.60	\N
36	6	7	80.30	\N
37	6	6	66.70	\N
38	6	5	78.40	\N
39	6	4	57.20	\N
40	6	3	41.40	\N
41	6	2	\N	\N
42	6	1	75.60	\N
43	7	7	82.50	\N
44	7	6	83.30	\N
45	7	5	67.20	\N
46	7	4	73.90	\N
47	7	3	27.10	\N
48	7	2	\N	\N
49	7	1	75.40	\N
50	8	7	78.10	\N
51	8	6	100.00	\N
52	8	5	65.00	\N
53	8	4	60.10	\N
54	8	3	30.00	\N
55	8	2	\N	\N
56	8	1	50.80	\N
57	9	7	52.70	\N
58	9	6	100.00	\N
59	9	5	62.30	\N
60	9	4	72.60	\N
61	9	3	40.80	\N
62	9	2	\N	\N
63	9	1	67.30	\N
64	10	7	73.50	\N
65	10	6	100.00	\N
66	10	5	62.60	\N
67	10	4	30.80	\N
68	10	3	21.40	\N
69	10	2	\N	\N
70	10	1	69.60	\N
71	11	7	83.20	\N
72	11	6	50.00	\N
73	11	5	61.50	\N
74	11	4	57.90	\N
75	11	3	52.00	\N
76	11	2	\N	\N
77	11	1	68.90	\N
78	12	7	79.10	\N
79	12	6	83.30	\N
80	12	5	61.10	\N
81	12	4	26.20	\N
82	12	3	29.50	\N
83	12	2	\N	\N
84	12	1	63.50	\N
85	13	7	71.40	\N
86	13	6	83.30	\N
87	13	5	59.10	\N
88	13	4	72.60	\N
89	13	3	26.20	\N
90	13	2	\N	\N
91	13	1	63.40	\N
92	14	7	98.60	\N
93	14	6	80.00	\N
94	14	5	1.70	\N
95	14	4	62.40	\N
96	14	3	66.50	\N
97	14	2	\N	\N
98	14	1	61.10	\N
99	15	7	71.70	\N
100	15	6	83.30	\N
101	15	5	57.90	\N
102	15	4	35.50	\N
103	15	3	31.70	\N
104	15	2	\N	\N
105	15	1	61.30	\N
106	16	7	89.80	\N
107	16	6	33.30	\N
108	16	5	51.20	\N
109	16	4	69.40	\N
110	16	3	54.60	\N
111	16	2	\N	\N
112	16	1	74.00	\N
113	17	7	52.10	\N
114	17	6	83.30	\N
115	17	5	49.60	\N
116	17	4	60.00	\N
117	17	3	48.40	\N
118	17	2	\N	\N
119	17	1	64.40	\N
120	18	7	89.70	\N
121	18	6	16.70	\N
122	18	5	60.00	\N
123	18	4	64.10	\N
124	18	3	62.60	\N
125	18	2	\N	\N
126	18	1	71.90	\N
127	19	7	76.50	\N
128	19	6	66.70	\N
129	19	5	55.00	\N
130	19	4	73.50	\N
131	19	3	41.50	\N
132	19	2	\N	\N
133	19	1	51.60	\N
134	20	7	33.50	\N
135	20	6	83.30	\N
136	20	5	64.80	\N
137	20	4	58.40	\N
138	20	3	33.60	\N
139	20	2	\N	\N
140	20	1	74.70	\N
141	21	7	97.60	\N
142	21	6	16.70	\N
143	21	5	34.70	\N
144	21	4	63.60	\N
145	21	3	78.00	\N
146	21	2	\N	\N
147	21	1	72.00	\N
148	22	7	92.30	\N
149	22	6	50.00	\N
150	22	5	37.60	\N
151	22	4	59.20	\N
152	22	3	54.20	\N
153	22	2	\N	\N
154	22	1	58.10	\N
155	23	7	86.30	\N
156	23	6	50.00	\N
157	23	5	59.40	\N
158	23	4	74.10	\N
159	23	3	54.10	\N
160	23	2	\N	\N
161	23	1	36.20	\N
162	24	7	78.10	\N
163	24	6	50.00	\N
164	24	5	60.20	\N
165	24	4	38.80	\N
166	24	3	30.80	\N
167	24	2	\N	\N
168	24	1	67.50	\N
169	25	7	94.30	\N
170	25	6	16.70	\N
171	25	5	72.40	\N
172	25	4	68.80	\N
173	25	3	62.60	\N
174	25	2	\N	\N
175	25	1	42.40	\N
176	26	7	20.00	\N
177	26	6	100.00	\N
178	26	5	72.20	\N
179	26	4	65.40	\N
180	26	3	31.60	\N
181	26	2	\N	\N
182	26	1	48.90	\N
183	27	7	70.90	\N
184	27	6	100.00	\N
185	27	5	\N	\N
186	27	4	89.30	\N
187	27	3	26.30	\N
188	27	2	\N	\N
189	27	1	73.10	\N
190	28	7	82.40	\N
191	28	6	33.30	\N
192	28	5	57.40	\N
193	28	4	34.60	\N
194	28	3	59.40	\N
195	28	2	\N	\N
196	28	1	53.90	\N
197	29	7	81.70	\N
198	29	6	33.30	\N
199	29	5	75.90	\N
200	29	4	47.30	\N
201	29	3	21.60	\N
202	29	2	\N	\N
203	29	1	59.80	\N
204	30	7	52.10	\N
205	30	6	33.30	\N
206	30	5	58.60	\N
207	30	4	80.30	\N
208	30	3	48.20	\N
209	30	2	\N	\N
210	30	1	73.00	\N
211	31	7	78.80	\N
212	31	6	33.30	\N
213	31	5	62.30	\N
214	31	4	56.10	\N
215	31	3	23.90	\N
216	31	2	\N	\N
217	31	1	64.70	\N
218	32	7	74.10	\N
219	32	6	83.30	\N
220	32	5	\N	\N
221	32	4	55.40	\N
222	32	3	28.20	\N
223	32	2	\N	\N
224	32	1	72.60	\N
225	33	7	75.10	\N
226	33	6	33.30	\N
227	33	5	53.50	\N
228	33	4	21.90	\N
229	33	3	30.80	\N
230	33	2	\N	\N
231	33	1	73.50	\N
232	34	7	53.00	\N
233	34	6	50.00	\N
234	34	5	63.40	\N
235	34	4	83.30	\N
236	34	3	29.70	\N
237	34	2	\N	\N
238	34	1	58.30	\N
239	35	7	21.90	\N
240	35	6	50.00	\N
241	35	5	61.00	\N
242	35	4	83.30	\N
243	35	3	42.70	\N
244	35	2	\N	\N
245	35	1	71.90	\N
246	36	7	91.20	\N
247	36	6	16.70	\N
248	36	5	29.70	\N
249	36	4	61.10	\N
250	36	3	70.00	\N
251	36	2	\N	\N
252	36	1	50.40	\N
253	37	7	93.60	\N
254	37	6	20.00	\N
255	37	5	23.30	\N
256	37	4	58.10	\N
257	37	3	46.20	\N
258	37	2	\N	\N
259	37	1	73.90	\N
260	38	7	93.80	\N
261	38	6	16.70	\N
262	38	5	3.30	\N
263	38	4	75.10	\N
264	38	3	57.70	\N
265	38	2	\N	\N
266	38	1	77.80	\N
267	39	7	66.70	\N
268	39	6	66.70	\N
269	39	5	\N	\N
270	39	4	58.10	\N
271	39	3	22.90	\N
272	39	2	\N	\N
273	39	1	78.10	\N
274	40	7	74.50	\N
275	40	6	33.30	\N
276	40	5	52.80	\N
277	40	4	35.20	\N
278	40	3	31.20	\N
279	40	2	\N	\N
280	40	1	52.50	\N
281	41	7	40.90	\N
282	41	6	50.00	\N
283	41	5	57.30	\N
284	41	4	42.00	\N
285	41	3	13.80	\N
286	41	2	\N	\N
287	41	1	71.10	\N
288	42	7	88.60	\N
289	42	6	20.00	\N
290	42	5	32.30	\N
291	42	4	48.80	\N
292	42	3	38.00	\N
293	42	2	\N	\N
294	42	1	53.90	\N
295	43	7	46.30	\N
296	43	6	33.30	\N
297	43	5	62.10	\N
298	43	4	59.00	\N
299	43	3	37.30	\N
300	43	2	\N	\N
301	43	1	51.80	\N
302	44	7	69.00	\N
303	44	6	50.00	\N
304	44	5	57.00	\N
305	44	4	33.00	\N
306	44	3	0.70	\N
307	44	2	\N	\N
308	44	1	54.20	\N
309	45	7	19.80	\N
310	45	6	33.30	\N
311	45	5	69.30	\N
312	45	4	45.10	\N
313	45	3	37.30	\N
314	45	2	\N	\N
315	45	1	58.40	\N
316	46	7	22.90	\N
317	46	6	50.00	\N
318	46	5	50.20	\N
319	46	4	49.40	\N
320	46	3	26.60	\N
321	46	2	\N	\N
322	46	1	62.70	\N
323	47	7	77.70	\N
324	47	6	33.30	\N
325	47	5	22.20	\N
326	47	4	36.60	\N
327	47	3	32.20	\N
328	47	2	\N	\N
329	47	1	42.20	\N
330	48	7	66.70	\N
331	48	6	16.70	\N
332	48	5	\N	\N
333	48	4	63.60	\N
334	48	3	44.10	\N
335	48	2	\N	\N
336	48	1	77.10	\N
337	49	7	93.70	\N
338	49	6	16.70	\N
339	49	5	\N	\N
340	49	4	42.10	\N
341	49	3	47.30	\N
342	49	2	\N	\N
343	49	1	47.90	\N
344	50	7	80.20	\N
345	50	6	16.70	\N
346	50	5	23.20	\N
347	50	4	21.70	\N
348	50	3	39.10	\N
349	50	2	\N	\N
350	50	1	45.10	\N
\.


--
-- Data for Name: category_variable_values; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.category_variable_values (value_id, var_value, score_id, var_id, no_score_reason) FROM stdin;
1	23.00	40	28	\N
2	35.10	6	28	\N
3	43.10	17	28	\N
4	11.30	10	28	\N
5	57.30	4	28	\N
6	97.90	1	28	\N
7	76.20	38	28	\N
8	48.50	49	28	\N
9	47.70	11	28	\N
10	49.80	23	28	\N
11	56.10	21	28	\N
12	36.00	13	28	\N
13	61.90	22	28	\N
14	26.40	31	28	\N
15	32.20	29	28	\N
16	48.50	43	28	\N
17	14.60	41	28	\N
18	14.20	47	28	\N
19	53.10	46	28	\N
20	84.90	5	28	\N
21	100.00	14	28	\N
22	37.20	26	28	\N
23	65.30	35	28	\N
24	10.90	24	28	\N
25	38.10	12	28	\N
26	49.80	8	28	\N
27	46.00	20	28	\N
28	17.20	9	28	\N
29	71.50	42	28	\N
30	84.10	36	28	\N
31	31.00	16	28	\N
32	70.30	25	28	\N
33	53.10	30	28	\N
34	40.20	27	28	\N
35	33.50	7	28	\N
36	20.50	15	28	\N
37	56.10	2	28	\N
38	50.20	45	28	\N
39	61.10	37	28	\N
40	37.20	50	28	\N
41	41.00	32	28	\N
42	33.50	33	28	\N
43	45.20	28	28	\N
44	61.50	19	28	\N
45	86.60	48	28	\N
46	79.10	18	28	\N
47	69.50	3	28	\N
48	0.00	44	28	\N
49	42.70	34	28	\N
50	33.10	39	28	\N
51	24.80	40	20	\N
52	84.20	6	20	\N
53	54.90	17	20	\N
54	77.70	10	20	\N
55	93.30	4	20	\N
56	72.10	1	20	\N
57	90.20	38	20	\N
58	50.10	49	20	\N
59	39.80	11	20	\N
60	42.10	23	20	\N
61	81.10	21	20	\N
62	60.80	13	20	\N
63	44.90	22	20	\N
64	0.00	31	20	\N
65	68.60	29	20	\N
66	85.90	43	20	\N
67	69.50	41	20	\N
68	42.10	47	20	\N
69	92.30	46	20	\N
70	87.00	5	20	\N
71	61.30	14	20	\N
72	53.10	26	20	\N
73	77.40	35	20	\N
74	43.00	24	20	\N
75	85.00	12	20	\N
76	83.20	8	20	\N
77	46.40	20	20	\N
78	30.60	9	20	\N
79	29.30	42	20	\N
80	49.80	36	20	\N
81	68.60	16	20	\N
82	63.50	25	20	\N
83	73.10	30	20	\N
84	31.60	27	20	\N
85	54.80	7	20	\N
86	77.80	15	20	\N
87	31.60	2	20	\N
88	50.30	45	20	\N
89	72.10	37	20	\N
90	63.00	50	20	\N
91	14.70	32	20	\N
92	74.00	33	20	\N
93	75.00	28	20	\N
94	15.70	19	20	\N
95	45.80	48	20	\N
96	37.60	18	20	\N
97	100.00	3	20	\N
98	49.40	44	20	\N
99	47.60	34	20	\N
100	40.30	39	20	\N
101	71.70	40	9	\N
102	85.10	6	9	\N
103	85.50	17	9	\N
104	91.80	10	9	\N
105	1.30	4	9	\N
106	81.70	1	9	\N
107	3.80	38	9	\N
108	\N	49	9	no congressional data
109	86.90	11	9	\N
110	92.20	23	9	\N
111	34.10	21	9	\N
112	80.80	13	9	\N
113	59.90	22	9	\N
114	100.00	31	9	\N
115	94.40	29	9	\N
116	80.80	43	9	\N
117	79.30	41	9	\N
118	1.80	47	9	\N
119	49.00	46	9	\N
120	65.90	5	9	\N
121	1.60	14	9	\N
122	86.40	26	9	\N
123	87.30	35	9	\N
124	88.00	24	9	\N
125	95.10	12	9	\N
126	97.80	8	9	\N
127	86.40	20	9	\N
128	93.30	9	9	\N
129	49.70	42	9	\N
130	78.00	36	9	\N
131	83.30	16	9	\N
132	86.90	25	9	\N
133	79.70	30	9	\N
134	\N	27	9	no congressional data
135	81.10	7	9	\N
136	85.50	15	9	\N
137	89.80	2	9	\N
138	94.70	45	9	\N
139	0.00	37	9	\N
140	2.20	50	9	\N
141	\N	32	9	no congressional data
142	74.80	33	9	\N
143	67.70	28	9	\N
144	90.90	19	9	\N
145	\N	48	9	no congressional data
146	79.10	18	9	\N
147	84.60	3	9	\N
148	71.00	44	9	\N
149	92.90	34	9	\N
150	\N	39	9	no congressional data
151	0.00	40	8	\N
152	100.00	6	8	\N
153	33.30	17	8	\N
154	0.00	10	8	\N
155	33.30	4	8	\N
156	11.10	1	8	\N
157	0.00	38	8	\N
158	\N	49	8	no congressional data
159	33.30	11	8	\N
160	0.00	23	8	\N
161	0.00	21	8	\N
162	0.00	13	8	\N
163	0.00	22	8	\N
164	0.00	31	8	\N
165	33.30	29	8	\N
166	11.10	43	8	\N
167	0.00	41	8	\N
168	0.00	47	8	\N
169	11.10	46	8	\N
170	11.10	5	8	\N
171	0.00	14	8	\N
172	55.60	26	8	\N
173	11.10	35	8	\N
174	0.00	24	8	\N
175	0.00	12	8	\N
176	0.00	8	8	\N
177	11.10	20	8	\N
178	11.10	9	8	\N
179	22.20	42	8	\N
180	11.10	36	8	\N
181	11.10	16	8	\N
182	66.70	25	8	\N
183	11.10	30	8	\N
184	\N	27	8	no congressional data
185	44.40	7	8	\N
186	0.00	15	8	\N
187	11.10	2	8	\N
188	44.40	45	8	\N
189	0.00	37	8	\N
190	0.00	50	8	\N
191	\N	32	8	no congressional data
192	0.00	33	8	\N
193	22.20	28	8	\N
194	0.00	19	8	\N
195	\N	48	8	no congressional data
196	11.10	18	8	\N
197	22.20	3	8	\N
198	0.00	44	8	\N
199	22.20	34	8	\N
200	\N	39	8	no congressional data
201	85.40	40	18	\N
202	68.20	6	18	\N
203	68.00	17	18	\N
204	76.40	10	18	\N
205	56.20	4	18	\N
206	74.10	1	18	\N
207	65.60	38	18	\N
208	89.90	49	18	\N
209	72.10	11	18	\N
210	73.90	23	18	\N
211	74.20	21	18	\N
212	100.00	13	18	\N
213	53.90	22	18	\N
214	80.30	31	18	\N
215	30.40	29	18	\N
216	50.60	43	18	\N
217	80.60	41	18	\N
218	53.90	47	18	\N
219	53.70	46	18	\N
220	63.50	5	18	\N
221	72.80	14	18	\N
222	61.20	26	18	\N
223	31.70	35	18	\N
224	93.00	24	18	\N
225	83.80	12	18	\N
226	0.00	8	18	\N
227	69.50	20	18	\N
228	67.30	9	18	\N
229	26.30	42	18	\N
230	65.50	36	18	\N
231	42.60	16	18	\N
232	49.60	25	18	\N
233	79.80	30	18	\N
234	70.30	27	18	\N
235	59.70	7	18	\N
236	83.70	15	18	\N
237	75.80	2	18	\N
238	61.30	45	18	\N
239	72.50	37	18	\N
240	74.10	50	18	\N
241	69.90	32	18	\N
242	85.60	33	18	\N
243	80.10	28	18	\N
244	77.80	19	18	\N
245	96.70	48	18	\N
246	57.10	18	18	\N
247	70.10	3	18	\N
248	56.20	44	18	\N
249	59.50	34	18	\N
250	84.50	39	18	\N
251	0.00	40	16	\N
252	0.00	6	16	\N
253	100.00	17	16	\N
254	100.00	10	16	\N
255	100.00	4	16	\N
256	100.00	1	16	\N
257	0.00	38	16	\N
258	0.00	49	16	\N
259	100.00	11	16	\N
260	0.00	23	16	\N
261	0.00	21	16	\N
262	0.00	13	16	\N
263	100.00	22	16	\N
264	0.00	31	16	\N
265	0.00	29	16	\N
266	0.00	43	16	\N
267	0.00	41	16	\N
268	0.00	47	16	\N
269	0.00	46	16	\N
270	0.00	5	16	\N
271	100.00	14	16	\N
272	100.00	26	16	\N
273	0.00	35	16	\N
274	0.00	24	16	\N
275	100.00	12	16	\N
276	100.00	8	16	\N
277	100.00	20	16	\N
278	100.00	9	16	\N
279	0.00	42	16	\N
280	0.00	36	16	\N
281	0.00	16	16	\N
282	0.00	25	16	\N
283	0.00	30	16	\N
284	100.00	27	16	\N
285	100.00	7	16	\N
286	100.00	15	16	\N
287	100.00	2	16	\N
288	0.00	45	16	\N
289	0.00	37	16	\N
290	0.00	50	16	\N
291	100.00	32	16	\N
292	0.00	33	16	\N
293	0.00	28	16	\N
294	0.00	19	16	\N
295	0.00	48	16	\N
296	0.00	18	16	\N
297	0.00	3	16	\N
298	0.00	44	16	\N
299	0.00	34	16	\N
300	0.00	39	16	\N
301	\N	40	14	\N
302	\N	6	14	\N
303	\N	17	14	\N
304	\N	10	14	\N
305	\N	4	14	\N
306	\N	1	14	\N
307	\N	38	14	\N
308	\N	49	14	\N
309	\N	11	14	\N
310	\N	23	14	\N
311	\N	21	14	\N
312	\N	13	14	\N
313	\N	22	14	\N
314	\N	31	14	\N
315	\N	29	14	\N
316	\N	43	14	\N
317	\N	41	14	\N
318	\N	47	14	\N
319	\N	46	14	\N
320	\N	5	14	\N
321	\N	14	14	\N
322	\N	26	14	\N
323	\N	35	14	\N
324	\N	24	14	\N
325	\N	12	14	\N
326	\N	8	14	\N
327	\N	20	14	\N
328	\N	9	14	\N
329	\N	42	14	\N
330	\N	36	14	\N
331	\N	16	14	\N
332	\N	25	14	\N
333	\N	30	14	\N
334	\N	27	14	\N
335	\N	7	14	\N
336	\N	15	14	\N
337	\N	2	14	\N
338	\N	45	14	\N
339	\N	37	14	\N
340	\N	50	14	\N
341	\N	32	14	\N
342	\N	33	14	\N
343	\N	28	14	\N
344	\N	19	14	\N
345	\N	48	14	\N
346	\N	18	14	\N
347	\N	3	14	\N
348	\N	44	14	\N
349	\N	34	14	\N
350	\N	39	14	\N
351	23.50	40	25	\N
352	41.00	6	25	\N
353	56.20	17	25	\N
354	20.60	10	25	\N
355	89.70	4	25	\N
356	73.70	1	25	\N
357	81.40	38	25	\N
358	81.20	49	25	\N
359	49.50	11	25	\N
360	58.80	23	25	\N
361	92.80	21	25	\N
362	14.20	13	25	\N
363	76.80	22	25	\N
364	36.30	31	25	\N
365	45.10	29	25	\N
366	38.90	43	25	\N
367	22.70	41	25	\N
368	33.00	47	25	\N
369	68.60	46	25	\N
370	97.40	5	25	\N
371	95.90	14	25	\N
372	60.10	26	25	\N
373	65.70	35	25	\N
374	34.30	24	25	\N
375	37.40	12	25	\N
376	34.30	8	25	\N
377	33.50	20	25	\N
378	58.20	9	25	\N
379	65.70	42	25	\N
380	73.50	36	25	\N
381	69.30	16	25	\N
382	83.00	25	25	\N
383	56.40	30	25	\N
384	12.60	27	25	\N
385	47.40	7	25	\N
386	15.20	15	25	\N
387	76.50	2	25	\N
388	59.50	45	25	\N
389	80.70	37	25	\N
390	40.50	50	25	\N
391	22.40	32	25	\N
392	25.30	33	25	\N
393	47.20	28	25	\N
394	29.60	19	25	\N
395	100.00	48	25	\N
396	69.10	18	25	\N
397	80.90	3	25	\N
398	7.00	44	25	\N
399	59.00	34	25	\N
400	0.00	39	25	\N
401	100.00	40	26	\N
402	100.00	6	26	\N
403	0.00	17	26	\N
404	100.00	10	26	\N
405	100.00	4	26	\N
406	100.00	1	26	\N
407	100.00	38	26	\N
408	100.00	49	26	\N
409	100.00	11	26	\N
410	100.00	23	26	\N
411	100.00	21	26	\N
412	100.00	13	26	\N
413	100.00	22	26	\N
414	100.00	31	26	\N
415	100.00	29	26	\N
416	0.00	43	26	\N
417	0.00	41	26	\N
418	100.00	47	26	\N
419	0.00	46	26	\N
420	100.00	5	26	\N
421	100.00	14	26	\N
422	0.00	26	26	\N
423	0.00	35	26	\N
424	100.00	24	26	\N
425	100.00	12	26	\N
426	100.00	8	26	\N
427	\N	20	26	no data
428	0.00	9	26	\N
429	100.00	42	26	\N
430	100.00	36	26	\N
431	100.00	16	26	\N
432	100.00	25	26	\N
433	0.00	30	26	\N
434	100.00	27	26	\N
435	100.00	7	26	\N
436	100.00	15	26	\N
437	100.00	2	26	\N
438	0.00	45	26	\N
439	100.00	37	26	\N
440	100.00	50	26	\N
441	100.00	32	26	\N
442	100.00	33	26	\N
443	100.00	28	26	\N
444	100.00	19	26	\N
445	0.00	48	26	\N
446	100.00	18	26	\N
447	100.00	3	26	\N
448	100.00	44	26	\N
449	0.00	34	26	\N
450	100.00	39	26	\N
451	100.00	40	27	\N
452	100.00	6	27	\N
453	100.00	17	27	\N
454	100.00	10	27	\N
455	100.00	4	27	\N
456	100.00	1	27	\N
457	100.00	38	27	\N
458	100.00	49	27	\N
459	100.00	11	27	\N
460	100.00	23	27	\N
461	100.00	21	27	\N
462	100.00	13	27	\N
463	100.00	22	27	\N
464	100.00	31	27	\N
465	100.00	29	27	\N
466	100.00	43	27	\N
467	100.00	41	27	\N
468	100.00	47	27	\N
469	0.00	46	27	\N
470	100.00	5	27	\N
471	100.00	14	27	\N
472	0.00	26	27	\N
473	0.00	35	27	\N
474	100.00	24	27	\N
475	100.00	12	27	\N
476	100.00	8	27	\N
477	\N	20	27	no data
478	100.00	9	27	\N
479	100.00	42	27	\N
480	100.00	36	27	\N
481	100.00	16	27	\N
482	100.00	25	27	\N
483	100.00	30	27	\N
484	100.00	27	27	\N
485	100.00	7	27	\N
486	100.00	15	27	\N
487	100.00	2	27	\N
488	0.00	45	27	\N
489	100.00	37	27	\N
490	100.00	50	27	\N
491	100.00	32	27	\N
492	100.00	33	27	\N
493	100.00	28	27	\N
494	100.00	19	27	\N
495	100.00	48	27	\N
496	100.00	18	27	\N
497	100.00	3	27	\N
498	100.00	44	27	\N
499	100.00	34	27	\N
500	100.00	39	27	\N
501	100.00	40	11	\N
502	0.00	6	11	\N
503	0.00	17	11	\N
504	100.00	10	11	\N
505	0.00	4	11	\N
506	0.00	1	11	\N
507	0.00	38	11	\N
508	0.00	49	11	\N
509	0.00	11	11	\N
510	100.00	23	11	\N
511	0.00	21	11	\N
512	100.00	13	11	\N
513	100.00	22	11	\N
514	0.00	31	11	\N
515	0.00	29	11	\N
516	0.00	43	11	\N
517	100.00	41	11	\N
518	100.00	47	11	\N
519	0.00	46	11	\N
520	0.00	5	11	\N
521	0.00	14	11	\N
522	100.00	26	11	\N
523	100.00	35	11	\N
524	100.00	24	11	\N
525	0.00	12	11	\N
526	100.00	8	11	\N
527	0.00	20	11	\N
528	100.00	9	11	\N
529	0.00	42	11	\N
530	0.00	36	11	\N
531	0.00	16	11	\N
532	0.00	25	11	\N
533	100.00	30	11	\N
534	100.00	27	11	\N
535	100.00	7	11	\N
536	0.00	15	11	\N
537	100.00	2	11	\N
538	100.00	45	11	\N
539	0.00	37	11	\N
540	0.00	50	11	\N
541	0.00	32	11	\N
542	0.00	33	11	\N
543	100.00	28	11	\N
544	0.00	19	11	\N
545	0.00	48	11	\N
546	0.00	18	11	\N
547	100.00	3	11	\N
548	100.00	44	11	\N
549	100.00	34	11	\N
550	0.00	39	11	\N
551	\N	40	23	\N
552	\N	6	23	\N
553	\N	17	23	\N
554	\N	10	23	\N
555	\N	4	23	\N
556	\N	1	23	\N
557	\N	38	23	\N
558	\N	49	23	\N
559	\N	11	23	\N
560	\N	23	23	\N
561	\N	21	23	\N
562	\N	13	23	\N
563	\N	22	23	\N
564	\N	31	23	\N
565	\N	29	23	\N
566	\N	43	23	\N
567	\N	41	23	\N
568	\N	47	23	\N
569	\N	46	23	\N
570	\N	5	23	\N
571	\N	14	23	\N
572	\N	26	23	\N
573	\N	35	23	\N
574	\N	24	23	\N
575	\N	12	23	\N
576	\N	8	23	\N
577	\N	20	23	\N
578	\N	9	23	\N
579	\N	42	23	\N
580	\N	36	23	\N
581	\N	16	23	\N
582	\N	25	23	\N
583	\N	30	23	\N
584	\N	27	23	\N
585	\N	7	23	\N
586	\N	15	23	\N
587	\N	2	23	\N
588	\N	45	23	\N
589	\N	37	23	\N
590	\N	50	23	\N
591	\N	32	23	\N
592	\N	33	23	\N
593	\N	28	23	\N
594	\N	19	23	\N
595	\N	48	23	\N
596	\N	18	23	\N
597	\N	3	23	\N
598	\N	44	23	\N
599	\N	34	23	\N
600	\N	39	23	\N
601	71.30	40	19	\N
602	0.00	6	19	\N
603	86.30	17	19	\N
604	72.60	10	19	\N
605	58.60	4	19	\N
606	84.50	1	19	\N
607	70.40	38	19	\N
608	68.70	49	19	\N
609	78.50	11	19	\N
610	74.50	23	19	\N
611	63.90	21	19	\N
612	75.00	13	19	\N
613	9.90	22	19	\N
614	63.40	31	19	\N
615	28.10	29	19	\N
616	70.40	43	19	\N
617	65.60	41	19	\N
618	65.50	47	19	\N
619	76.00	46	19	\N
620	73.60	5	19	\N
621	67.90	14	19	\N
622	65.20	26	19	\N
623	74.90	35	19	\N
624	81.70	24	19	\N
625	64.60	12	19	\N
626	71.70	8	19	\N
627	100.00	20	19	\N
628	53.20	9	19	\N
629	91.10	42	19	\N
630	68.00	36	19	\N
631	51.30	16	19	\N
632	80.20	25	19	\N
633	65.90	30	19	\N
634	86.10	27	19	\N
635	60.60	7	19	\N
636	59.00	15	19	\N
637	27.90	2	19	\N
638	43.90	45	19	\N
639	57.90	37	19	\N
640	78.70	50	19	\N
641	72.90	32	19	\N
642	74.80	33	19	\N
643	58.30	28	19	\N
644	80.80	19	19	\N
645	79.30	48	19	\N
646	31.90	18	19	\N
647	61.30	3	19	\N
648	56.10	44	19	\N
649	68.30	34	19	\N
650	69.40	39	19	\N
651	\N	40	22	\N
652	\N	6	22	\N
653	\N	17	22	\N
654	\N	10	22	\N
655	\N	4	22	\N
656	\N	1	22	\N
657	\N	38	22	\N
658	\N	49	22	\N
659	\N	11	22	\N
660	\N	23	22	\N
661	\N	21	22	\N
662	\N	13	22	\N
663	\N	22	22	\N
664	\N	31	22	\N
665	\N	29	22	\N
666	\N	43	22	\N
667	\N	41	22	\N
668	\N	47	22	\N
669	\N	46	22	\N
670	\N	5	22	\N
671	\N	14	22	\N
672	\N	26	22	\N
673	\N	35	22	\N
674	\N	24	22	\N
675	\N	12	22	\N
676	\N	8	22	\N
677	\N	20	22	\N
678	\N	9	22	\N
679	\N	42	22	\N
680	\N	36	22	\N
681	\N	16	22	\N
682	\N	25	22	\N
683	\N	30	22	\N
684	\N	27	22	\N
685	\N	7	22	\N
686	\N	15	22	\N
687	\N	2	22	\N
688	\N	45	22	\N
689	\N	37	22	\N
690	\N	50	22	\N
691	\N	32	22	\N
692	\N	33	22	\N
693	\N	28	22	\N
694	\N	19	22	\N
695	\N	48	22	\N
696	\N	18	22	\N
697	\N	3	22	\N
698	\N	44	22	\N
699	\N	34	22	\N
700	\N	39	22	\N
701	39.40	40	29	\N
702	47.60	6	29	\N
703	53.70	17	29	\N
704	31.60	10	29	\N
705	80.90	4	29	\N
706	36.50	1	29	\N
707	39.30	38	29	\N
708	46.10	49	29	\N
709	56.30	11	29	\N
710	58.50	23	29	\N
711	100.00	21	29	\N
712	16.50	13	29	\N
713	46.40	22	29	\N
714	21.40	31	29	\N
715	10.90	29	29	\N
716	26.10	43	29	\N
717	12.90	41	29	\N
718	50.20	47	29	\N
719	0.00	46	29	\N
720	62.70	5	29	\N
721	33.00	14	29	\N
722	25.90	26	29	\N
723	20.20	35	29	\N
724	50.80	24	29	\N
725	21.00	12	29	\N
726	10.30	8	29	\N
727	21.10	20	29	\N
728	64.50	9	29	\N
729	4.40	42	29	\N
730	55.90	36	29	\N
731	78.30	16	29	\N
732	55.00	25	29	\N
733	43.30	30	29	\N
734	12.40	27	29	\N
735	20.80	7	29	\N
736	42.80	15	29	\N
737	27.00	2	29	\N
738	24.30	45	29	\N
739	31.30	37	29	\N
740	40.90	50	29	\N
741	15.40	32	29	\N
742	28.10	33	29	\N
743	73.50	28	29	\N
744	21.60	19	29	\N
745	1.50	48	29	\N
746	46.00	18	29	\N
747	38.40	3	29	\N
748	1.50	44	29	\N
749	16.80	34	29	\N
750	12.70	39	29	\N
751	0.00	40	6	\N
752	100.00	6	6	\N
753	100.00	17	6	\N
754	0.00	10	6	\N
755	100.00	4	6	\N
756	100.00	1	6	\N
757	100.00	38	6	\N
758	0.00	49	6	\N
759	100.00	11	6	\N
760	100.00	23	6	\N
761	100.00	21	6	\N
762	100.00	13	6	\N
763	100.00	22	6	\N
764	100.00	31	6	\N
765	0.00	29	6	\N
766	100.00	43	6	\N
767	100.00	41	6	\N
768	0.00	47	6	\N
769	0.00	46	6	\N
770	100.00	5	6	\N
771	100.00	14	6	\N
772	100.00	26	6	\N
773	100.00	35	6	\N
774	100.00	24	6	\N
775	0.00	12	6	\N
776	100.00	8	6	\N
777	100.00	20	6	\N
778	100.00	9	6	\N
779	0.00	42	6	\N
780	100.00	36	6	\N
781	100.00	16	6	\N
782	100.00	25	6	\N
783	100.00	30	6	\N
784	100.00	27	6	\N
785	100.00	7	6	\N
786	100.00	15	6	\N
787	100.00	2	6	\N
788	100.00	45	6	\N
789	100.00	37	6	\N
790	0.00	50	6	\N
791	100.00	32	6	\N
792	0.00	33	6	\N
793	0.00	28	6	\N
794	100.00	19	6	\N
795	100.00	48	6	\N
796	100.00	18	6	\N
797	100.00	3	6	\N
798	0.00	44	6	\N
799	100.00	34	6	\N
800	100.00	39	6	\N
801	100.00	40	5	\N
802	100.00	6	5	\N
803	100.00	17	5	\N
804	0.00	10	5	\N
805	100.00	4	5	\N
806	100.00	1	5	\N
807	100.00	38	5	\N
808	100.00	49	5	\N
809	100.00	11	5	\N
810	100.00	23	5	\N
811	100.00	21	5	\N
812	100.00	13	5	\N
813	100.00	22	5	\N
814	100.00	31	5	\N
815	100.00	29	5	\N
816	100.00	43	5	\N
817	100.00	41	5	\N
818	100.00	47	5	\N
819	100.00	46	5	\N
820	100.00	5	5	\N
821	100.00	14	5	\N
822	100.00	26	5	\N
823	100.00	35	5	\N
824	0.00	24	5	\N
825	100.00	12	5	\N
826	0.00	8	5	\N
827	100.00	20	5	\N
828	100.00	9	5	\N
829	0.00	42	5	\N
830	100.00	36	5	\N
831	100.00	16	5	\N
832	100.00	25	5	\N
833	100.00	30	5	\N
834	100.00	27	5	\N
835	100.00	7	5	\N
836	100.00	15	5	\N
837	100.00	2	5	\N
838	100.00	45	5	\N
839	100.00	37	5	\N
840	0.00	50	5	\N
841	100.00	32	5	\N
842	0.00	33	5	\N
843	100.00	28	5	\N
844	100.00	19	5	\N
845	100.00	48	5	\N
846	100.00	18	5	\N
847	100.00	3	5	\N
848	100.00	44	5	\N
849	100.00	34	5	\N
850	0.00	39	5	\N
851	\N	40	7	\N
852	\N	6	7	\N
853	\N	17	7	\N
854	\N	10	7	\N
855	\N	4	7	\N
856	\N	1	7	\N
857	\N	38	7	\N
858	\N	49	7	no congressional data
859	\N	11	7	\N
860	\N	23	7	\N
861	\N	21	7	\N
862	\N	13	7	\N
863	\N	22	7	\N
864	\N	31	7	\N
865	\N	29	7	\N
866	\N	43	7	\N
867	\N	41	7	\N
868	\N	47	7	\N
869	\N	46	7	\N
870	\N	5	7	\N
871	\N	14	7	\N
872	\N	26	7	\N
873	\N	35	7	\N
874	\N	24	7	\N
875	\N	12	7	\N
876	\N	8	7	\N
877	\N	20	7	\N
878	\N	9	7	\N
879	\N	42	7	\N
880	\N	36	7	\N
881	\N	16	7	\N
882	\N	25	7	\N
883	\N	30	7	\N
884	\N	27	7	no congressional data
885	\N	7	7	\N
886	\N	15	7	\N
887	\N	2	7	\N
888	\N	45	7	\N
889	\N	37	7	\N
890	\N	50	7	\N
891	\N	32	7	no congressional data
892	\N	33	7	\N
893	\N	28	7	\N
894	\N	19	7	\N
895	\N	48	7	no congressional data
896	\N	18	7	\N
897	\N	3	7	\N
898	\N	44	7	\N
899	\N	34	7	\N
900	\N	39	7	no congressional data
901	0.00	40	13	\N
902	100.00	6	13	\N
903	100.00	17	13	\N
904	100.00	10	13	\N
905	100.00	4	13	\N
906	100.00	1	13	\N
907	100.00	38	13	\N
908	100.00	49	13	\N
909	100.00	11	13	\N
910	100.00	23	13	\N
911	100.00	21	13	\N
912	100.00	13	13	\N
913	0.00	22	13	\N
914	100.00	31	13	\N
915	100.00	29	13	\N
916	100.00	43	13	\N
917	100.00	41	13	\N
918	0.00	47	13	\N
919	100.00	46	13	\N
920	100.00	5	13	\N
921	100.00	14	13	\N
922	100.00	26	13	\N
923	100.00	35	13	\N
924	100.00	24	13	\N
925	100.00	12	13	\N
926	100.00	8	13	\N
927	100.00	20	13	\N
928	100.00	9	13	\N
929	100.00	42	13	\N
930	100.00	36	13	\N
931	0.00	16	13	\N
932	100.00	25	13	\N
933	0.00	30	13	\N
934	100.00	27	13	\N
935	0.00	7	13	\N
936	100.00	15	13	\N
937	100.00	2	13	\N
938	0.00	45	13	\N
939	100.00	37	13	\N
940	100.00	50	13	\N
941	100.00	32	13	\N
942	100.00	33	13	\N
943	0.00	28	13	\N
944	100.00	19	13	\N
945	100.00	48	13	\N
946	100.00	18	13	\N
947	100.00	3	13	\N
948	100.00	44	13	\N
949	100.00	34	13	\N
950	100.00	39	13	\N
951	86.60	40	10	\N
952	50.00	6	10	\N
953	30.00	17	10	\N
954	96.00	10	10	\N
955	30.20	4	10	\N
956	76.60	1	10	\N
957	6.30	38	10	\N
958	\N	49	10	no congressional data
959	64.20	11	10	\N
960	85.80	23	10	\N
961	70.00	21	10	\N
962	96.60	13	10	\N
963	52.90	22	10	\N
964	87.00	31	10	\N
965	100.00	29	10	\N
966	94.30	43	10	\N
967	92.50	41	10	\N
968	64.80	47	10	\N
969	90.60	46	10	\N
970	62.50	5	10	\N
971	3.60	14	10	\N
972	74.70	26	10	\N
973	84.50	35	10	\N
974	92.70	24	10	\N
975	88.30	12	10	\N
976	97.30	8	10	\N
977	96.80	20	10	\N
978	82.40	9	10	\N
979	25.00	42	10	\N
980	0.00	36	10	\N
981	59.10	16	10	\N
982	63.70	25	10	\N
983	85.00	30	10	\N
984	\N	27	10	no congressional data
985	76.10	7	10	\N
986	88.30	15	10	\N
987	70.80	2	10	\N
988	68.70	45	10	\N
989	70.00	37	10	\N
990	67.40	50	10	\N
991	\N	32	10	no congressional data
992	85.80	33	10	\N
993	82.30	28	10	\N
994	74.10	19	10	\N
995	\N	48	10	no congressional data
996	89.80	18	10	\N
997	73.10	3	10	\N
998	100.00	44	10	\N
999	75.00	34	10	\N
1000	\N	39	10	no congressional data
1001	0.00	40	17	\N
1002	100.00	6	17	\N
1003	100.00	17	17	\N
1004	100.00	10	17	\N
1005	100.00	4	17	\N
1006	100.00	1	17	\N
1007	0.00	38	17	\N
1008	0.00	49	17	\N
1009	0.00	11	17	\N
1010	0.00	23	17	\N
1011	0.00	21	17	\N
1012	100.00	13	17	\N
1013	0.00	22	17	\N
1014	0.00	31	17	\N
1015	0.00	29	17	\N
1016	0.00	43	17	\N
1017	0.00	41	17	\N
1018	0.00	47	17	\N
1019	100.00	46	17	\N
1020	100.00	5	17	\N
1021	100.00	14	17	\N
1022	100.00	26	17	\N
1023	0.00	35	17	\N
1024	0.00	24	17	\N
1025	100.00	12	17	\N
1026	100.00	8	17	\N
1027	100.00	20	17	\N
1028	100.00	9	17	\N
1029	0.00	42	17	\N
1030	0.00	36	17	\N
1031	100.00	16	17	\N
1032	0.00	25	17	\N
1033	0.00	30	17	\N
1034	100.00	27	17	\N
1035	100.00	7	17	\N
1036	100.00	15	17	\N
1037	100.00	2	17	\N
1038	0.00	45	17	\N
1039	0.00	37	17	\N
1040	0.00	50	17	\N
1041	100.00	32	17	\N
1042	0.00	33	17	\N
1043	0.00	28	17	\N
1044	100.00	19	17	\N
1045	0.00	48	17	\N
1046	0.00	18	17	\N
1047	100.00	3	17	\N
1048	0.00	44	17	\N
1049	0.00	34	17	\N
1050	100.00	39	17	\N
1051	\N	40	24	\N
1052	\N	6	24	\N
1053	\N	17	24	\N
1054	\N	10	24	\N
1055	\N	4	24	\N
1056	\N	1	24	\N
1057	\N	38	24	\N
1058	\N	49	24	\N
1059	\N	11	24	\N
1060	\N	23	24	\N
1061	\N	21	24	\N
1062	\N	13	24	\N
1063	\N	22	24	\N
1064	\N	31	24	\N
1065	\N	29	24	\N
1066	\N	43	24	\N
1067	\N	41	24	\N
1068	\N	47	24	\N
1069	\N	46	24	\N
1070	\N	5	24	\N
1071	\N	14	24	\N
1072	\N	26	24	\N
1073	\N	35	24	\N
1074	\N	24	24	\N
1075	\N	12	24	\N
1076	\N	8	24	\N
1077	\N	20	24	\N
1078	\N	9	24	\N
1079	\N	42	24	\N
1080	\N	36	24	\N
1081	\N	16	24	\N
1082	\N	25	24	\N
1083	\N	30	24	\N
1084	\N	27	24	\N
1085	\N	7	24	\N
1086	\N	15	24	\N
1087	\N	2	24	\N
1088	\N	45	24	\N
1089	\N	37	24	\N
1090	\N	50	24	\N
1091	\N	32	24	\N
1092	\N	33	24	\N
1093	\N	28	24	\N
1094	\N	19	24	\N
1095	\N	48	24	\N
1096	\N	18	24	\N
1097	\N	3	24	\N
1098	\N	44	24	\N
1099	\N	34	24	\N
1100	\N	39	24	\N
1101	\N	40	21	\N
1102	\N	6	21	\N
1103	\N	17	21	\N
1104	\N	10	21	\N
1105	\N	4	21	\N
1106	\N	1	21	\N
1107	\N	38	21	\N
1108	\N	49	21	\N
1109	\N	11	21	\N
1110	\N	23	21	\N
1111	\N	21	21	\N
1112	\N	13	21	\N
1113	\N	22	21	\N
1114	\N	31	21	\N
1115	\N	29	21	\N
1116	\N	43	21	\N
1117	\N	41	21	\N
1118	\N	47	21	\N
1119	\N	46	21	\N
1120	\N	5	21	\N
1121	\N	14	21	\N
1122	\N	26	21	\N
1123	\N	35	21	\N
1124	\N	24	21	\N
1125	\N	12	21	\N
1126	\N	8	21	\N
1127	\N	20	21	\N
1128	\N	9	21	\N
1129	\N	42	21	\N
1130	\N	36	21	\N
1131	\N	16	21	\N
1132	\N	25	21	\N
1133	\N	30	21	\N
1134	\N	27	21	\N
1135	\N	7	21	\N
1136	\N	15	21	\N
1137	\N	2	21	\N
1138	\N	45	21	\N
1139	\N	37	21	\N
1140	\N	50	21	\N
1141	\N	32	21	\N
1142	\N	33	21	\N
1143	\N	28	21	\N
1144	\N	19	21	\N
1145	\N	48	21	\N
1146	\N	18	21	\N
1147	\N	3	21	\N
1148	\N	44	21	\N
1149	\N	34	21	\N
1150	\N	39	21	\N
1151	100.00	40	12	\N
1152	100.00	6	12	\N
1153	100.00	17	12	\N
1154	100.00	10	12	\N
1155	100.00	4	12	\N
1156	100.00	1	12	\N
1157	0.00	38	12	\N
1158	0.00	49	12	\N
1159	100.00	11	12	\N
1160	100.00	23	12	\N
1161	0.00	21	12	\N
1162	100.00	13	12	\N
1163	100.00	22	12	\N
1164	100.00	31	12	\N
1165	100.00	29	12	\N
1166	100.00	43	12	\N
1167	100.00	41	12	\N
1168	100.00	47	12	\N
1169	0.00	46	12	\N
1170	100.00	5	12	\N
1171	\N	14	12	one-term limit
1172	100.00	26	12	\N
1173	100.00	35	12	\N
1174	100.00	24	12	\N
1175	100.00	12	12	\N
1176	100.00	8	12	\N
1177	100.00	20	12	\N
1178	100.00	9	12	\N
1179	\N	42	12	one-term limit
1180	0.00	36	12	\N
1181	100.00	16	12	\N
1182	0.00	25	12	\N
1183	100.00	30	12	\N
1184	100.00	27	12	\N
1185	100.00	7	12	\N
1186	100.00	15	12	\N
1187	100.00	2	12	\N
1188	100.00	45	12	\N
1189	\N	37	12	one-term limit
1190	0.00	50	12	\N
1191	100.00	32	12	\N
1192	100.00	33	12	\N
1193	100.00	28	12	\N
1194	100.00	19	12	\N
1195	0.00	48	12	\N
1196	0.00	18	12	\N
1197	100.00	3	12	\N
1198	100.00	44	12	\N
1199	100.00	34	12	\N
1200	100.00	39	12	\N
1201	0.00	40	3	\N
1202	0.00	6	3	\N
1203	0.00	17	3	\N
1204	0.00	10	3	\N
1205	100.00	4	3	\N
1206	100.00	1	3	\N
1207	100.00	38	3	\N
1208	0.00	49	3	\N
1209	0.00	11	3	\N
1210	0.00	23	3	\N
1211	100.00	21	3	\N
1212	100.00	13	3	\N
1213	100.00	22	3	\N
1214	0.00	31	3	\N
1215	100.00	29	3	\N
1216	0.00	43	3	\N
1217	0.00	41	3	\N
1218	0.00	47	3	\N
1219	100.00	46	3	\N
1220	100.00	5	3	\N
1221	100.00	14	3	\N
1222	100.00	26	3	\N
1223	100.00	35	3	\N
1224	0.00	24	3	\N
1225	0.00	12	3	\N
1226	100.00	8	3	\N
1227	0.00	20	3	\N
1228	100.00	9	3	\N
1229	100.00	42	3	\N
1230	0.00	36	3	\N
1231	100.00	16	3	\N
1232	100.00	25	3	\N
1233	100.00	30	3	\N
1234	100.00	27	3	\N
1235	0.00	7	3	\N
1236	0.00	15	3	\N
1237	0.00	2	3	\N
1238	0.00	45	3	\N
1239	100.00	37	3	\N
1240	0.00	50	3	\N
1241	0.00	32	3	\N
1242	0.00	33	3	\N
1243	0.00	28	3	\N
1244	100.00	19	3	\N
1245	100.00	48	3	\N
1246	100.00	18	3	\N
1247	100.00	3	3	\N
1248	0.00	44	3	\N
1249	100.00	34	3	\N
1250	100.00	39	3	\N
1251	0.00	40	15	\N
1252	100.00	6	15	\N
1253	100.00	17	15	\N
1254	100.00	10	15	\N
1255	100.00	4	15	\N
1256	100.00	1	15	\N
1257	0.00	38	15	\N
1258	0.00	49	15	\N
1259	0.00	11	15	\N
1260	0.00	23	15	\N
1261	0.00	21	15	\N
1262	100.00	13	15	\N
1263	0.00	22	15	\N
1264	0.00	31	15	\N
1265	0.00	29	15	\N
1266	0.00	43	15	\N
1267	0.00	41	15	\N
1268	0.00	47	15	\N
1269	100.00	46	15	\N
1270	0.00	5	15	\N
1271	100.00	14	15	\N
1272	100.00	26	15	\N
1273	0.00	35	15	\N
1274	0.00	24	15	\N
1275	100.00	12	15	\N
1276	100.00	8	15	\N
1277	100.00	20	15	\N
1278	100.00	9	15	\N
1279	0.00	42	15	\N
1280	0.00	36	15	\N
1281	0.00	16	15	\N
1282	0.00	25	15	\N
1283	0.00	30	15	\N
1284	100.00	27	15	\N
1285	100.00	7	15	\N
1286	100.00	15	15	\N
1287	100.00	2	15	\N
1288	0.00	45	15	\N
1289	0.00	37	15	\N
1290	0.00	50	15	\N
1291	100.00	32	15	\N
1292	0.00	33	15	\N
1293	0.00	28	15	\N
1294	100.00	19	15	\N
1295	0.00	48	15	\N
1296	0.00	18	15	\N
1297	100.00	3	15	\N
1298	0.00	44	15	\N
1299	0.00	34	15	\N
1300	100.00	39	15	\N
1301	0.00	40	4	\N
1302	0.00	6	4	\N
1303	100.00	17	4	\N
1304	100.00	10	4	\N
1305	0.00	4	4	\N
1306	0.00	1	4	\N
1307	0.00	38	4	\N
1308	0.00	49	4	\N
1309	0.00	11	4	\N
1310	100.00	23	4	\N
1311	0.00	21	4	\N
1312	0.00	13	4	\N
1313	0.00	22	4	\N
1314	100.00	31	4	\N
1315	0.00	29	4	\N
1316	100.00	43	4	\N
1317	0.00	41	4	\N
1318	0.00	47	4	\N
1319	0.00	46	4	\N
1320	0.00	5	4	\N
1321	0.00	14	4	\N
1322	0.00	26	4	\N
1323	0.00	35	4	\N
1324	100.00	24	4	\N
1325	0.00	12	4	\N
1326	0.00	8	4	\N
1327	0.00	20	4	\N
1328	0.00	9	4	\N
1329	100.00	42	4	\N
1330	0.00	36	4	\N
1331	0.00	16	4	\N
1332	0.00	25	4	\N
1333	100.00	30	4	\N
1334	100.00	27	4	\N
1335	100.00	7	4	\N
1336	0.00	15	4	\N
1337	0.00	2	4	\N
1338	0.00	45	4	\N
1339	0.00	37	4	\N
1340	0.00	50	4	\N
1341	0.00	32	4	\N
1342	100.00	33	4	\N
1343	0.00	28	4	\N
1344	0.00	19	4	\N
1345	0.00	48	4	\N
1346	0.00	18	4	\N
1347	0.00	3	4	\N
1348	0.00	44	4	\N
1349	100.00	34	4	\N
1350	100.00	39	4	\N
1351	82.10	40	2	\N
1352	91.50	6	2	\N
1353	7.90	17	2	\N
1354	75.90	10	2	\N
1355	85.30	4	2	\N
1356	87.00	1	2	\N
1357	87.30	38	2	\N
1358	91.50	49	2	\N
1359	80.40	11	2	\N
1360	84.80	23	2	\N
1361	81.70	21	2	\N
1362	84.20	13	2	\N
1363	8.20	22	2	\N
1364	7.70	31	2	\N
1365	8.60	29	2	\N
1366	8.20	43	2	\N
1367	8.60	41	2	\N
1368	81.10	47	2	\N
1369	8.30	46	2	\N
1370	8.70	5	2	\N
1371	8.00	14	2	\N
1372	8.40	26	2	\N
1373	100.00	35	2	\N
1374	8.90	24	2	\N
1375	8.50	12	2	\N
1376	90.80	8	2	\N
1377	86.80	20	2	\N
1378	83.80	9	2	\N
1379	8.60	42	2	\N
1380	100.00	36	2	\N
1381	86.80	16	2	\N
1382	81.90	25	2	\N
1383	7.50	30	2	\N
1384	93.60	27	2	\N
1385	91.30	7	2	\N
1386	7.40	15	2	\N
1387	97.80	2	2	\N
1388	0.00	45	2	\N
1389	8.40	37	2	\N
1390	85.90	50	2	\N
1391	82.80	32	2	\N
1392	8.10	33	2	\N
1393	84.50	28	2	\N
1394	85.20	19	2	\N
1395	8.20	48	2	\N
1396	8.50	18	2	\N
1397	91.20	3	2	\N
1398	84.60	44	2	\N
1399	8.40	34	2	\N
1400	7.50	39	2	\N
1401	29.00	40	1	\N
1402	51.60	6	1	\N
1403	52.40	17	1	\N
1404	9.10	10	1	\N
1405	49.20	4	1	\N
1406	89.30	1	1	\N
1407	63.10	38	1	\N
1408	61.10	49	1	\N
1409	67.10	11	1	\N
1410	59.90	23	1	\N
1411	0.00	21	1	\N
1412	51.20	13	1	\N
1413	46.80	22	1	\N
1414	29.00	31	1	\N
1415	75.00	29	1	\N
1416	45.60	43	1	\N
1417	43.30	41	1	\N
1418	38.50	47	1	\N
1419	88.10	46	1	\N
1420	66.30	5	1	\N
1421	66.30	14	1	\N
1422	84.10	26	1	\N
1423	100.00	35	1	\N
1424	24.20	24	1	\N
1425	48.80	12	1	\N
1426	69.80	8	1	\N
1427	63.90	20	1	\N
1428	52.00	9	1	\N
1429	84.50	42	1	\N
1430	66.70	36	1	\N
1431	29.40	16	1	\N
1432	31.00	25	1	\N
1433	74.20	30	1	\N
1434	42.10	27	1	\N
1435	52.40	7	1	\N
1436	5.60	15	1	\N
1437	83.30	2	1	\N
1438	70.60	45	1	\N
1439	40.50	37	1	\N
1440	44.00	50	1	\N
1441	49.60	32	1	\N
1442	23.00	33	1	\N
1443	23.00	28	1	\N
1444	55.60	19	1	\N
1445	73.40	48	1	\N
1446	75.80	18	1	\N
1447	80.20	3	1	\N
1448	13.50	44	1	\N
1449	91.30	34	1	\N
1450	40.90	39	1	\N
\.


--
-- Data for Name: news_articles; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.news_articles (article_id, headline, summary, source_name, source_url, published_at, is_national, created_at) FROM stdin;
1	Texas Lawmakers Consider Campaign Finance Disclosure Bill	A proposed bill would expand transparency requirements for state campaign spending.	Sample News	https://example.com/texas-campaign-finance-disclosure	2026-07-09 11:37:38.71932-04	f	2026-07-14 11:37:38.71932-04
2	Wisconsin Reform Groups Renew Redistricting Push	Advocacy groups are calling for an independent redistricting process before the next map cycle.	Sample News	https://example.com/wisconsin-redistricting-reform	2026-07-12 11:37:38.71932-04	f	2026-07-14 11:37:38.71932-04
\.


--
-- Data for Name: news_state_updates; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.news_state_updates (article_id, state_id, score_id, score_delta) FROM stdin;
1	43	28	46.80
2	49	34	43.70
\.


--
-- Data for Name: reform_categories; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.reform_categories (category_id, category, cat_description, cat_weight) FROM stdin;
1	Campaign Finance	\N	\N
2	Civil Society	\N	\N
3	Demographics	\N	\N
4	Electoral Participation	\N	\N
5	Fair Representation	\N	\N
6	Political Accountability	\N	\N
7	Political and Institutional Factors	\N	\N
\.


--
-- Data for Name: reform_category_variables; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.reform_category_variables (var_id, var_name, var_description, category_id) FROM stdin;
1	voter_turnout	\N	4
2	voter_registration	\N	4
3	same_day_registration	\N	4
4	strict_id	\N	4
5	online_registration	\N	4
6	no_excuse_absentee	\N	4
7	partisan_fairness	\N	5
8	competitiveness	\N	5
9	compactness	\N	5
10	per_county_split	\N	5
11	elected_supreme_justice	\N	6
12	retention_election_justice	\N	6
13	partisan_justice_election	\N	6
14	court_curbing_bill	\N	6
15	statutory_initiative	\N	6
16	constitutional_initiative	\N	6
17	popular_referendum	\N	6
18	congressional_money_percapita	\N	1
19	legislative_money_percapita	\N	1
20	campaign_finance_index	\N	1
21	protest_index	\N	2
22	local_news	\N	2
23	free_speech	\N	2
24	press_incidents	\N	2
25	democratic_leaning	\N	7
26	divided_government	\N	7
27	divided_legislatures	\N	7
28	bachelor_share	\N	3
29	minority_share	\N	3
\.


--
-- Data for Name: reform_scores; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.reform_scores (score_id, state_id, scored_at, score, grade) FROM stdin;
1	6	2026-07-14 11:37:35.596511-04	61.90	A
2	37	2026-07-14 11:37:35.596511-04	60.70	A
3	47	2026-07-14 11:37:35.596511-04	59.40	A
4	5	2026-07-14 11:37:35.596511-04	58.30	A
5	20	2026-07-14 11:37:35.596511-04	57.60	A
6	2	2026-07-14 11:37:35.596511-04	57.10	A
7	35	2026-07-14 11:37:35.596511-04	56.90	A
8	26	2026-07-14 11:37:35.596511-04	55.00	A
9	28	2026-07-14 11:37:35.596511-04	55.20	A
10	4	2026-07-14 11:37:35.596511-04	54.70	A
11	9	2026-07-14 11:37:35.596511-04	52.50	B
12	25	2026-07-14 11:37:35.596511-04	52.50	B
13	12	2026-07-14 11:37:35.596511-04	51.80	B
14	21	2026-07-14 11:37:35.596511-04	51.60	B
15	36	2026-07-14 11:37:35.596511-04	51.10	B
16	31	2026-07-14 11:37:35.596511-04	50.40	B
17	3	2026-07-14 11:37:35.596511-04	50.40	B
18	46	2026-07-14 11:37:35.596511-04	49.60	B
19	44	2026-07-14 11:37:35.596511-04	49.50	B
20	27	2026-07-14 11:37:35.596511-04	49.20	B
21	11	2026-07-14 11:37:35.596511-04	49.10	B
22	13	2026-07-14 11:37:35.596511-04	48.70	B
23	10	2026-07-14 11:37:35.596511-04	48.30	B
24	24	2026-07-14 11:37:35.596511-04	47.50	B
25	32	2026-07-14 11:37:35.596511-04	47.90	B
26	22	2026-07-14 11:37:35.596511-04	47.10	B
27	34	2026-07-14 11:37:35.596511-04	47.10	B
28	43	2026-07-14 11:37:35.596511-04	46.80	C
29	15	2026-07-14 11:37:35.596511-04	45.20	C
30	33	2026-07-14 11:37:35.596511-04	44.90	C
31	14	2026-07-14 11:37:35.596511-04	44.00	C
32	41	2026-07-14 11:37:35.596511-04	43.90	C
33	42	2026-07-14 11:37:35.596511-04	43.40	C
34	49	2026-07-14 11:37:35.596511-04	43.70	C
35	23	2026-07-14 11:37:35.596511-04	42.60	C
36	30	2026-07-14 11:37:35.596511-04	42.60	C
37	39	2026-07-14 11:37:35.596511-04	42.50	C
38	7	2026-07-14 11:37:35.596511-04	41.60	C
39	50	2026-07-14 11:37:35.596511-04	39.90	C
40	1	2026-07-14 11:37:35.596511-04	40.30	C
41	17	2026-07-14 11:37:35.596511-04	39.20	D
42	29	2026-07-14 11:37:35.596511-04	38.50	D
43	16	2026-07-14 11:37:35.596511-04	38.90	D
44	48	2026-07-14 11:37:35.596511-04	38.60	D
45	38	2026-07-14 11:37:35.596511-04	36.50	D
46	19	2026-07-14 11:37:35.596511-04	36.00	D
47	18	2026-07-14 11:37:35.596511-04	34.40	D
48	45	2026-07-14 11:37:35.596511-04	34.20	D
49	8	2026-07-14 11:37:35.596511-04	33.70	D
50	40	2026-07-14 11:37:35.596511-04	33.10	D
\.


--
-- Data for Name: states; Type: TABLE DATA; Schema: public; Owner: milishah
--

COPY public.states (state_id, state_name, abbreviation, electoral_votes) FROM stdin;
1	Alabama	AL	9
2	Alaska	AK	3
3	Arizona	AZ	11
4	Arkansas	AR	6
5	California	CA	55
6	Colorado	CO	9
7	Connecticut	CT	7
8	Delaware	DE	3
9	Florida	FL	29
10	Georgia	GA	16
11	Hawaii	HI	4
12	Idaho	ID	4
13	Illinois	IL	20
14	Indiana	IN	11
15	Iowa	IA	6
16	Kansas	KS	6
17	Kentucky	KY	8
18	Louisiana	LA	8
19	Maine	ME	4
20	Maryland	MD	10
21	Massachusetts	MA	11
22	Michigan	MI	16
23	Minnesota	MN	10
24	Mississippi	MS	6
25	Missouri	MO	10
26	Montana	MT	3
27	Nebraska	NE	5
28	Nevada	NV	6
29	New Hampshire	NH	4
30	New Jersey	NJ	14
31	New Mexico	NM	5
32	New York	NY	29
33	North Carolina	NC	15
34	North Dakota	ND	3
35	Ohio	OH	18
36	Oklahoma	OK	7
37	Oregon	OR	7
38	Pennsylvania	PA	20
39	Rhode Island	RI	4
40	South Carolina	SC	9
41	South Dakota	SD	3
42	Tennessee	TN	11
43	Texas	TX	38
44	Utah	UT	6
45	Vermont	VT	3
46	Virginia	VA	13
47	Washington	WA	12
48	West Virginia	WV	5
49	Wisconsin	WI	10
50	Wyoming	WY	3
\.


--
-- Name: action_pathways_pathway_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.action_pathways_pathway_id_seq', 2, true);


--
-- Name: category_scores_cat_score_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.category_scores_cat_score_id_seq', 350, true);


--
-- Name: category_variable_values_value_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.category_variable_values_value_id_seq', 1450, true);


--
-- Name: news_articles_article_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.news_articles_article_id_seq', 2, true);


--
-- Name: reform_categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.reform_categories_category_id_seq', 7, true);


--
-- Name: reform_category_variables_var_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.reform_category_variables_var_id_seq', 29, true);


--
-- Name: reform_scores_score_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.reform_scores_score_id_seq', 50, true);


--
-- Name: states_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: milishah
--

SELECT pg_catalog.setval('public.states_state_id_seq', 50, true);


--
-- Name: action_pathways action_pathways_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.action_pathways
    ADD CONSTRAINT action_pathways_pkey PRIMARY KEY (pathway_id);


--
-- Name: category_scores category_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_scores
    ADD CONSTRAINT category_scores_pkey PRIMARY KEY (cat_score_id);


--
-- Name: category_scores category_scores_score_id_category_id_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_scores
    ADD CONSTRAINT category_scores_score_id_category_id_key UNIQUE (score_id, category_id);


--
-- Name: category_variable_values category_variable_values_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_variable_values
    ADD CONSTRAINT category_variable_values_pkey PRIMARY KEY (value_id);


--
-- Name: news_articles news_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_articles
    ADD CONSTRAINT news_articles_pkey PRIMARY KEY (article_id);


--
-- Name: news_articles news_articles_source_url_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_articles
    ADD CONSTRAINT news_articles_source_url_key UNIQUE (source_url);


--
-- Name: news_state_updates news_state_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_state_updates
    ADD CONSTRAINT news_state_updates_pkey PRIMARY KEY (article_id, state_id);


--
-- Name: news_state_updates news_state_updates_score_id_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_state_updates
    ADD CONSTRAINT news_state_updates_score_id_key UNIQUE (score_id);


--
-- Name: reform_categories reform_categories_category_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_categories
    ADD CONSTRAINT reform_categories_category_key UNIQUE (category);


--
-- Name: reform_categories reform_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_categories
    ADD CONSTRAINT reform_categories_pkey PRIMARY KEY (category_id);


--
-- Name: reform_category_variables reform_category_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_category_variables
    ADD CONSTRAINT reform_category_variables_pkey PRIMARY KEY (var_id);


--
-- Name: reform_category_variables reform_category_variables_var_name_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_category_variables
    ADD CONSTRAINT reform_category_variables_var_name_key UNIQUE (var_name);


--
-- Name: reform_scores reform_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_scores
    ADD CONSTRAINT reform_scores_pkey PRIMARY KEY (score_id);


--
-- Name: reform_scores reform_scores_state_id_scored_at_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_scores
    ADD CONSTRAINT reform_scores_state_id_scored_at_key UNIQUE (state_id, scored_at);


--
-- Name: states states_abbreviation_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_abbreviation_key UNIQUE (abbreviation);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (state_id);


--
-- Name: states states_state_name_key; Type: CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_state_name_key UNIQUE (state_name);


--
-- Name: idx_category_scores_score; Type: INDEX; Schema: public; Owner: milishah
--

CREATE INDEX idx_category_scores_score ON public.category_scores USING btree (score_id);


--
-- Name: idx_news_published; Type: INDEX; Schema: public; Owner: milishah
--

CREATE INDEX idx_news_published ON public.news_articles USING btree (published_at DESC);


--
-- Name: idx_pathways_state; Type: INDEX; Schema: public; Owner: milishah
--

CREATE INDEX idx_pathways_state ON public.action_pathways USING btree (state_id);


--
-- Name: idx_reform_scores_state; Type: INDEX; Schema: public; Owner: milishah
--

CREATE INDEX idx_reform_scores_state ON public.reform_scores USING btree (state_id);


--
-- Name: idx_reform_scores_state_latest; Type: INDEX; Schema: public; Owner: milishah
--

CREATE INDEX idx_reform_scores_state_latest ON public.reform_scores USING btree (state_id, scored_at DESC, score_id DESC);


--
-- Name: reform_scores delete_old_scores; Type: TRIGGER; Schema: public; Owner: milishah
--

CREATE TRIGGER delete_old_scores AFTER INSERT ON public.reform_scores FOR EACH ROW EXECUTE FUNCTION public.keep_latest_3_reform_scores();


--
-- Name: news_state_updates fill_score_delta; Type: TRIGGER; Schema: public; Owner: milishah
--

CREATE TRIGGER fill_score_delta BEFORE INSERT OR UPDATE ON public.news_state_updates FOR EACH ROW EXECUTE FUNCTION public.calc_score_delta();


--
-- Name: action_pathways action_pathways_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.action_pathways
    ADD CONSTRAINT action_pathways_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.reform_categories(category_id);


--
-- Name: action_pathways action_pathways_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.action_pathways
    ADD CONSTRAINT action_pathways_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(state_id);


--
-- Name: category_scores category_scores_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_scores
    ADD CONSTRAINT category_scores_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.reform_categories(category_id) ON DELETE CASCADE;


--
-- Name: category_scores category_scores_score_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_scores
    ADD CONSTRAINT category_scores_score_id_fkey FOREIGN KEY (score_id) REFERENCES public.reform_scores(score_id) ON DELETE CASCADE;


--
-- Name: category_variable_values category_variable_values_score_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_variable_values
    ADD CONSTRAINT category_variable_values_score_id_fkey FOREIGN KEY (score_id) REFERENCES public.reform_scores(score_id) ON DELETE CASCADE;


--
-- Name: category_variable_values category_variable_values_var_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.category_variable_values
    ADD CONSTRAINT category_variable_values_var_id_fkey FOREIGN KEY (var_id) REFERENCES public.reform_category_variables(var_id) ON DELETE CASCADE;


--
-- Name: news_state_updates news_state_updates_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_state_updates
    ADD CONSTRAINT news_state_updates_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.news_articles(article_id) ON DELETE CASCADE;


--
-- Name: news_state_updates news_state_updates_score_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_state_updates
    ADD CONSTRAINT news_state_updates_score_id_fkey FOREIGN KEY (score_id) REFERENCES public.reform_scores(score_id) ON DELETE CASCADE;


--
-- Name: news_state_updates news_state_updates_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.news_state_updates
    ADD CONSTRAINT news_state_updates_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(state_id) ON DELETE CASCADE;


--
-- Name: reform_category_variables reform_category_variables_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_category_variables
    ADD CONSTRAINT reform_category_variables_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.reform_categories(category_id);


--
-- Name: reform_scores reform_scores_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: milishah
--

ALTER TABLE ONLY public.reform_scores
    ADD CONSTRAINT reform_scores_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(state_id);


--
-- PostgreSQL database dump complete
--

\unrestrict nYro6VNvMoKpwosz3tYkDofuhPyiOMDUPyfUqUBJ1O2dxYtY3LCWVNtkbhK4MAt

