use rustler::{Encoder, Env, Term};
use std::collections::HashMap;

/// Value representation for mq results
#[derive(Debug, Clone)]
pub enum MqValue {
    Array(Vec<MqValue>),
    Dict(HashMap<String, MqValue>),
    Markdown { text: String },
}

impl MqValue {
    pub fn is_empty(&self) -> bool {
        match self {
            MqValue::Array(arr) => arr.is_empty(),
            MqValue::Dict(dict) => dict.is_empty(),
            MqValue::Markdown { text } => text.is_empty(),
        }
    }

    pub fn text(&self) -> String {
        match self {
            MqValue::Array(arr) => arr
                .iter()
                .map(|v| v.text())
                .collect::<Vec<String>>()
                .join("\n"),
            MqValue::Dict(dict) => dict
                .iter()
                .map(|(k, v)| format!("{}: {}", k, v.text()))
                .collect::<Vec<String>>()
                .join("\n"),
            MqValue::Markdown { text } => text.clone(),
        }
    }
}

impl Encoder for MqValue {
    fn encode<'a>(&self, env: Env<'a>) -> Term<'a> {
        match self {
            MqValue::Array(arr) => arr.encode(env),
            MqValue::Dict(dict) => dict.encode(env),
            MqValue::Markdown { text } => {
                // Return string for simple cases
                text.encode(env)
            }
        }
    }
}

impl From<mq_lang::RuntimeValue> for MqValue {
    fn from(value: mq_lang::RuntimeValue) -> Self {
        match value {
            mq_lang::RuntimeValue::Array(arr) => {
                MqValue::Array(arr.into_iter().map(|v| v.into()).collect())
            }
            mq_lang::RuntimeValue::Dict(map) => MqValue::Dict(
                map.into_iter()
                    .map(|(k, v)| (k.as_str().to_string(), v.into()))
                    .collect(),
            ),
            mq_lang::RuntimeValue::Markdown(node, _) => MqValue::Markdown {
                text: node.to_string(),
            },
            mq_lang::RuntimeValue::String(s) => MqValue::Markdown { text: s },
            mq_lang::RuntimeValue::Symbol(sym) => MqValue::Markdown {
                text: sym.as_str().to_string(),
            },
            mq_lang::RuntimeValue::Number(n) => MqValue::Markdown {
                text: n.to_string(),
            },
            mq_lang::RuntimeValue::Boolean(b) => MqValue::Markdown {
                text: b.to_string(),
            },
            mq_lang::RuntimeValue::Function(..)
            | mq_lang::RuntimeValue::NativeFunction(..)
            | mq_lang::RuntimeValue::Module(..)
            | mq_lang::RuntimeValue::Ast(_)
            | mq_lang::RuntimeValue::None => MqValue::Markdown {
                text: String::new(),
            },
        }
    }
}
