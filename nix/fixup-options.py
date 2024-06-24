#!/usr/bin/env python
import sys
import json
import markdown
from pygments import highlight
from pygments.lexers import NixLexer
from pygments.formatters import HtmlFormatter

if (len(sys.argv) - 1) % 2 != 0:
  print("Usage: path/to/options.json https://example.com/option/ path/to/other/options.json https://example.com/other_option/")
  sys.exit(1)

def code(code):
  assert code["_type"] == 'literalExpression'
  return highlight(code["text"], NixLexer(), HtmlFormatter())

out = []

for i in range(1,len(sys.argv),2):
  file = open(sys.argv[i])
  url = sys.argv[i+1]
  data = json.load(file)

  for key in data:
    entry = data[key]
    entry["name"] = key
    del entry["loc"]
    entry["declarations"] = list(map(lambda x: f"{url}{x[51:]}",entry["declarations"]))

    entry["description"] = markdown.markdown(entry["description"])
    if 'default' in entry:
      entry['default'] = code(entry["default"])
    if 'example' in entry:
      entry['example'] = code(entry["example"])
    out.append(entry)


print(json.dumps(out))
