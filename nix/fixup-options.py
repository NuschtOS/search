#!/usr/bin/env python
import sys
import json
import markdown
from pygments import highlight
from pygments.lexers import NixLexer
from pygments.formatters import HtmlFormatter

file = open(sys.argv[1])
url = sys.argv[2]
data = json.load(file)

out = []

def code(code):
  assert code["_type"] == 'literalExpression'
  return highlight(code["text"], NixLexer(), HtmlFormatter())

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
