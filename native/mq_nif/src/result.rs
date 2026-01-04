use rustler::{Encoder, Env, Term};

use crate::{atoms, value::MqValue};

/// Result of an mq query execution
#[derive(Debug, Clone)]
pub struct MqResult {
    pub values: Vec<MqValue>,
}

impl MqResult {
    /// Create a new MqResult from a vector of values
    pub fn new(values: Vec<MqValue>) -> Self {
        Self { values }
    }

    /// Get the text representation of all values joined by newlines
    pub fn text(&self) -> String {
        self.values
            .iter()
            .filter(|v| !v.is_empty())
            .map(|v| v.text())
            .collect::<Vec<String>>()
            .join("\n")
    }

    /// Get the filtered values (non-empty)
    pub fn filtered_values(&self) -> Vec<String> {
        self.values
            .iter()
            .filter(|v| !v.is_empty())
            .map(|v| v.text())
            .collect()
    }
}

impl Encoder for MqResult {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        // Create an Elixir map with :values and :text keys
        let values_list = self.filtered_values();
        let text_string = self.text();

        // Build map manually using rustler's map_new
        let map = Term::map_new(env);
        let map = map
            .map_put(atoms::values().encode(env), values_list.encode(env))
            .expect("Failed to add values key");
        map.map_put(atoms::text().encode(env), text_string.encode(env))
            .expect("Failed to add text key")
    }
}
