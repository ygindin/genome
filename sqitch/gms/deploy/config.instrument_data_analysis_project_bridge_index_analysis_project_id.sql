-- Deploy config.instrument_data_analysis_project_bridge_index_analysis_project_id
-- requires: config_instrument_data_analysis_project_bridge

BEGIN;

CREATE INDEX instrument_data_analysis_project_bridge_analysis_project_id_idx ON config.instrument_data_analysis_project_bridge (analysis_project_id);

COMMIT;