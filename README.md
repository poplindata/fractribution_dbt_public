

### Setup steps

1. Configure the `conversion_clause` macro to filter your raw Snowplow events to successful conversion events.
2. Configure the `conversion_value` macro to return the value of the conversion event.
3. Configure the default `channel_classification` macro to yield your expected channels. The ROAS calculations / attribution calculations will run against these channel definitions.

### Running

1. Create the required UDFs by running the create UDFs macro - `dbt run-operation create_udfs`. This only needs to be run once as this creates permanent UDFs.
2. Ensure the setup steps have been completed above.
3. Run `dbt run`

### TODO

- Refactor Python code so it doesn't mutate a table and instead creates a brand new table

### Differences to Fractribution

There are some changes from the original Fractribution code that have been noted below.

- Temporary UDFs have been converted to persistent / permanent UDFs
- Some temporary tables converted to permanent tables
- Users without a user_id are treated as 'anonymous' ('f') users and the domain_userid is used to identify these sessions
- Users with a user_id are treated as identified ('u') users
- Templating is now run almost entirely within dbt rather than the custom SQL / Jinja templating in the original Fractribution project
- Some SQL / calculations still take place in the original script. These may eventually be migrated over entirely to SQL based logic.
- Channel changes and contributions within a session can be considered using the `consider_intrasession_channels` variable.

### Intrasession channels

In Google Analytics (Universal Analytics) a new session is started if a campaign source changes (referrer of campaign tagged URL) which is used in Fractribution. Snowplow utilises activity based sessionisation rather than campaign based sessionisation. Setting `consider_instasession_channels` to `false` will take only the campaign information from the first page view in a given Snowplow session and not give credit to other channels in the converting session if they occur after the initial page view. 