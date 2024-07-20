local default_prompt = [[
You are the backend of an AI-powered code completion engine. Your task is to
provide code suggestions based on the user's input. The user's code will be
enclosed in markers:

- `<beginCode>`: Start of the code context
- `<cursorPosition>`: Current cursor location
- `<endCode>`: End of the code context
]]

local default_guidelines = [[
Guidelines:
1. Offer completions after the `<cursorPosition>` marker.
2. Make sure you have maintained the user's existing whitespace and indentation.
   This is REALLY IMPORTANT!
3. Provide multiple completion options when possible.
4. Return completions separated by the marker <endCompletion>.
5. The returned message will be further parsed and processed. DO NOT include
   additional comments or markdown code block fences. Return the result directly.
6. Keep each completion option concise, limiting it to a single line or a few lines.]]

local default_fewshots = {
    {
        role = 'user',
        content = [[
# language: python
<beginCode>
def fibonacci(n):
    <cursorPosition>

fib(5)
<endCode>]],
    },
    {
        role = 'assistant',
        content = [[
    '''
    Recursive Fibonacci implementation
    '''
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)
<endCompletion>
    '''
    Iterative Fibonacci implementation
    '''
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
<endCompletion>
]],
    },
}

local n_completion_template = '7. Provide at most %d completion items.'

-- use {{{ and }}} to wrap placeholders, which will be further processesed in other function
local default_system_template = '{{{prompt}}}\n{{{guidelines}}}\n{{{n_completion_template}}}'

local M = {
    provider = 'codestral',
    context_window = 12800, -- the maximum total characters of the context before and after cursor
    context_ratio = 0.6,
    -- when the total characters exceed the context window, the ratio of
    -- context before cursor and after cursor, the larger the ratio the more
    -- context before cursor will be used.
    throttle = 1000, -- only send the request every x milliseconds, use 0 to disable throttle.
    notify = true, -- show notification when request is sent
    request_timeout = 3, -- the timeout of the request in seconds
    -- if completion item has multiple lines, create another completion item only containing its first line.
    add_single_line_entry = true,
    -- The number of completion items (encoded as part of the prompt for the
    -- chat LLM) requested from the language model. It's important to note that
    -- when 'add_single_line_entry' is set to true, the actual number of
    -- returned items may exceed this value. Additionally, the LLM cannot
    -- guarantee the exact number of completion items specified, as this
    -- parameter serves only as a prompt guideline.
    n_completions = 3,
    provider_options = {
        codestral = {
            model = 'codestral-latest',
            optional = {
                stop = nil, -- the identifier to stop the completion generation
                max_tokens = nil,
            },
        },
        openai = {
            model = 'gpt-4o-mini',
            system = {
                template = default_system_template,
                prompt = default_prompt,
                guidelines = default_guidelines,
                n_completion_template = n_completion_template,
            },
            few_shots = default_fewshots,
            optional = {
                stop = nil,
                max_tokens = nil,
            },
        },
        claude = {
            max_tokens = 512,
            model = 'claude-3-5-sonnet-20240620',
            system = {
                template = default_system_template,
                prompt = default_prompt,
                guidelines = default_guidelines,
                n_completion_template = n_completion_template,
            },
            few_shots = default_fewshots,
            optional = {
                stop_sequences = nil,
            },
        },
        openai_compatible = {
            model = 'codestral-mamba-latest',
            system = {
                template = default_system_template,
                prompt = default_prompt,
                guidelines = default_guidelines,
                n_completion_template = n_completion_template,
            },
            few_shots = default_fewshots,
            end_point = 'https://api.mistral.ai/v1/chat/completions',
            api_key = 'MISTRAL_API_KEY',
            name = 'Mistral',
            optional = {
                stop = nil,
                max_tokens = nil,
            },
        },
        gemini = {
            model = 'gemini-1.5-flash-latest',
            system = {
                template = default_system_template,
                prompt = default_prompt,
                guidelines = default_guidelines,
                n_completion_template = n_completion_template,
            },
            few_shots = default_fewshots,
            optional = {
                -- generationConfig = {
                --     stopSequences = {},
                --     maxOutputTokens = 256,
                --     topP = 0.8,
                -- },
            },
        },
        huggingface = {
            end_point = 'https://api-inference.huggingface.co/models/bigcode/starcoder2-3b',
            type = 'completion', -- chat or completion
            strategies = {
                completion = {
                    markers = {
                        prefix = '<fim_prefix>',
                        suffix = '<fim_suffix>',
                        middle = '<fim_middle>',
                    },
                    strategy = 'PSM', -- PSM, SPM or PM
                },
            },
            optional = {
                parameters = {
                    stop = { '<fim_prefix>', '<fim_suffix>', '<fim_middle>', '<|endoftext|>' },
                    max_tokens = 128,
                },
            },
        },
    },
}

return M
