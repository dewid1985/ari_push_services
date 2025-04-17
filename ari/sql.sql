
CREATE TABLE rate.base_by_guest_amt (
                                        id bigserial NOT NULL,
                                        base_by_guest_amts_id bigint,
                                        max_age integer,
                                        min_age integer,
                                        amount_before_tax double precision,
                                        amount_after_tax double precision,
                                        number_of_quests integer,
                                        age_qualifying_code varchar(32),
                                        inserted_at timestamp,
                                        updated_at timestamp,
                                        CONSTRAINT base_by_guest_amt_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.base_by_guest_amts (
                                         id bigserial NOT NULL,
                                         rate_id bigint,
                                         inserted_at timestamp,
                                         updated_at timestamp,
                                         CONSTRAINT base_by_guest_amts_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.rate (
                           id bigserial NOT NULL,
                           rates_id bigint,
                           inventory_type_code varchar(32),
                           currency_code varchar(3),
                           rate_time_unit varchar(32),
                           min_los integer,
                           max_los integer,
                           sun boolean,
                           mon boolean,
                           tue boolean,
                           weds boolean,
                           thur boolean,
                           fri boolean,
                           sat boolean,
                           insterted_at timestamp,
                           updated_at timestamp,
                           CONSTRAINT rate_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.rates (
                            id bigserial NOT NULL,
                            rate_plan_id bigint,
                            insterted_at timestamp,
                            updated_at timestamp,
                            CONSTRAINT rates_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.unique_id (
                                id bigserial NOT NULL,
                                rate_plan_id bigint,
                                type varchar(256),
                                code varchar(16),
                                inserted_at timestamp,
                                updated_at timestamp,
                                CONSTRAINT unique_id_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.destination_systems_code (
                                               id bigserial NOT NULL,
                                               rate_plan_id bigint,
                                               insterted_at timestamp,
                                               updated_at timestamp,
                                               CONSTRAINT destination_systems_code_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.destination_system_code (
                                              id bigserial NOT NULL,
                                              destination_systems_code_id smallint,
                                              text varchar(32),
                                              inserted_at timestamp,
                                              updated_at timestamp,
                                              CONSTRAINT destination_system_code_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.rate_plan (
                                id bigserial NOT NULL,
                                rate_plans_id bigint,
                                rate_plan_code varchar(32),
                                rate_plan_notif_type varchar,
                                start date,
                                "end" date,
                                inserted_at timestamp,
                                updated_at timestamp,
                                CONSTRAINT rate_plan_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.rate_plans (
                                 id bigserial NOT NULL,
                                 ota_rate_plan_notif_rq_id bigint,
                                 hotel_code varchar(16),
                                 insterted_at timestamp,
                                 updated_at timestamp,
                                 CONSTRAINT rate_plans_pkey PRIMARY KEY (id)
);

CREATE TABLE rate.ota_hotel_rate_plan_notif_rq (
                                                   id bigserial NOT NULL,
                                                   time_stamp timestamptz,
                                                   version varchar(16),
                                                   message_content_code varchar(8),
                                                   inserted_at timestamp,
                                                   updated_at timestamptz,
                                                   CONSTRAINT messages_pkey PRIMARY KEY (id)
);

ALTER TABLE rate.base_by_guest_amt ADD CONSTRAINT base_by_guest_amt_base_by_guest_amts_id_fkey FOREIGN KEY (base_by_guest_amts_id)
    REFERENCES rate.base_by_guest_amts (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.base_by_guest_amts ADD CONSTRAINT base_by_guest_amts_rate_id_fkey FOREIGN KEY (rate_id)
    REFERENCES rate.rate (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.rate ADD CONSTRAINT rate_rates_id_fkey FOREIGN KEY (rates_id)
    REFERENCES rate.rates (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.rates ADD CONSTRAINT rates_rate_plan_id FOREIGN KEY (rate_plan_id)
    REFERENCES rate.rate_plan (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.unique_id ADD CONSTRAINT unique_id_rate_plan_id_fkey FOREIGN KEY (rate_plan_id)
    REFERENCES rate.rate_plan (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.destination_systems_code ADD CONSTRAINT destination_systems_code_rate_plan_id_fkey FOREIGN KEY (rate_plan_id)
    REFERENCES rate.rate_plan (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.destination_system_code ADD CONSTRAINT destination_systems_code_destination_systems_code_id_fkey FOREIGN KEY (destination_systems_code_id)
    REFERENCES rate.destination_systems_code (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.rate_plan ADD CONSTRAINT rate_plan_rate_plans_id_fkey FOREIGN KEY (rate_plans_id)
    REFERENCES rate.rate_plans (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE rate.rate_plans ADD CONSTRAINT rate_plans_ota_rate_plan_notif_rq_id_fkey FOREIGN KEY (ota_rate_plan_notif_rq_id)
    REFERENCES rate.ota_hotel_rate_plan_notif_rq (id) MATCH SIMPLE
    ON DELETE NO ACTION ON UPDATE NO ACTION;



