mod atoms;
mod result;
mod value;

use std::collections::HashMap;

use result::MqResult;
use rustler::{Atom, Encoder, Env, Error, NifMap, Term};
use value::MqValue;

/// Input format for mq queries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
enum InputFormat {
    #[default]
    Markdown,
    Mdx,
    Text,
    Html,
    Raw,
    Null,
}

/// Options for running mq queries
#[derive(Debug, Clone, Copy, Default)]
struct Options {
    input_format: InputFormat,
}

impl<'a> rustler::Decoder<'a> for Options {
    fn decode(term: Term<'a>) -> Result<Self, Error> {
        let map: HashMap<Atom, Atom> = term.decode()?;
        let input_format = map.get(&atoms::input_format()).cloned();

        Ok(Options {
            input_format: parse_input_format(input_format),
        })
    }
}

fn parse_input_format(atom: Option<Atom>) -> InputFormat {
    match atom {
        Some(a) => {
            if a == atoms::mdx() {
                InputFormat::Mdx
            } else if a == atoms::text() {
                InputFormat::Text
            } else if a == atoms::html() {
                InputFormat::Html
            } else if a == atoms::raw() {
                InputFormat::Raw
            } else if a == atoms::null() {
                InputFormat::Null
            } else {
                InputFormat::Markdown // Default for unknown atoms
            }
        }
        None => InputFormat::Markdown, // Default when no format specified
    }
}

/// Options for HTML to Markdown conversion
#[derive(Debug, Clone, Copy, NifMap, Default)]
struct ConversionOptions {
    extract_scripts_as_code_blocks: bool,
    generate_front_matter: bool,
    use_title_as_h1: bool,
}

/// Run an mq query on the provided content
#[rustler::nif]
fn run<'a>(
    env: Env<'a>,
    code: String,
    content: String,
    options: Term<'a>,
) -> Result<Term<'a>, Error> {
    // Parse options from Elixir map
    let opts: Options = options.decode().unwrap_or_default();
    // Create engine and load builtin modules
    let mut engine = mq_lang::DefaultEngine::default();
    engine.load_builtin_module();

    // Parse input based on format
    let input = match opts.input_format {
        InputFormat::Markdown => mq_lang::parse_markdown_input(&content),
        InputFormat::Mdx => mq_lang::parse_mdx_input(&content),
        InputFormat::Text => mq_lang::parse_text_input(&content),
        InputFormat::Html => mq_lang::parse_html_input(&content),
        InputFormat::Raw => Ok(mq_lang::raw_input(&content)),
        InputFormat::Null => Ok(mq_lang::null_input()),
    }
    .map_err(|e| Error::Term(Box::new(format!("Error parsing input: {}", e))))?;

    // Execute query
    let values = engine
        .eval(&code, input.into_iter())
        .map_err(|e| Error::Term(Box::new(format!("Error evaluating query: {}", e))))?;

    // Convert to MqResult
    let result = MqResult::new(values.into_iter().map(MqValue::from).collect());

    // Encode and return as {:ok, result}
    Ok((atoms::ok(), result).encode(env))
}

/// Convert HTML to Markdown
#[rustler::nif]
fn html_to_markdown(content: String, options: Term) -> Result<String, Error> {
    // Parse conversion options
    let opts: ConversionOptions = options.decode().unwrap_or_default();
    // Convert HTML to Markdown
    let markdown = mq_markdown::convert_html_to_markdown(
        &content,
        mq_markdown::ConversionOptions {
            extract_scripts_as_code_blocks: opts.extract_scripts_as_code_blocks,
            generate_front_matter: opts.generate_front_matter,
            use_title_as_h1: opts.use_title_as_h1,
        },
    )
    .map_err(|e| {
        Error::Term(Box::new(format!(
            "Error converting HTML to Markdown: {}",
            e
        )))
    })?;

    Ok(markdown)
}

rustler::init!("Elixir.Mq.Native");
