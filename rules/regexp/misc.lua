--[[
Copyright (c) 2011-2016, Vsevolod Stakhov <vsevolod@highsecure.ru>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]--


local reconf = config['regexp']

reconf['HTML_META_REFRESH_URL'] = {
  -- Requires options { check_attachements = true; }
  re = '/<meta\\s+http-equiv="refresh"\\s+content="\\d+\\s*;\\s*url=/{sa_raw_body}i',
  description = "Has HTML Meta refresh URL",
  score = 5.0,
  one_shot = true,
  group = 'HTML'
}

reconf['HAS_DATA_URI'] = {
  -- Requires options { check_attachements = true; }
  re = '/data:[^\\/]+\\/[^; ]+;base64,/{sa_raw_body}i',
  description = "Has Data URI encoding",
  group = 'HTML',
  one_shot = true,
}

reconf['DATA_URI_OBFU'] = {
  -- Requires options { check_attachements = true; }
  re = '/data:text\\/(?:plain|html);base64,/{sa_raw_body}i',
  description = "Uses Data URI encoding to obfuscate plain or HTML in base64",
  group = 'HTML',
  one_shot = true,
  score = 2.0
}

reconf['INTRODUCTION'] = {
  re = '/\\b(?:my name is\\b|(?:i am|this is)\\s+(?:mr|mrs|ms|miss|master|sir|prof(?:essor)?|d(?:octo)?r|rev(?:erend)?)(?:\\.|\\b))/{sa_body}i',
  description = "Sender introduces themselves",
  score = 2.0,
  one_shot = true,
  group = 'scams'
}

-- Message contains a link to a .onion URI (Tor hidden service)
local onion_uri_v2 = '/[a-z0-9]{16}\\.onion?/{url}i'
local onion_uri_v3 = '/[a-z0-9]{56}\\.onion?/{url}i'
reconf['HAS_ONION_URI'] = {
    re = string.format('(%s | %s)', onion_uri_v2, onion_uri_v3),
    description = 'Contains .onion hidden service URI',
    score = 0.0,
    group = 'experimental'
}

local my_victim = [[/(?:victim|prey)/{words}]]
local your_webcam = [[/webcam/{words}]]
local your_onan = [[/(?:mast[ur]{2}bati(?:on|ng)|onanism|solitary)/{words}]]
local password_in_words = [[/^pass(?:(?:word)|(?:phrase))$/i{words}]]
local btc_wallet_address = [[/^[13][0-9a-zA-Z]{25,34}$/{words}]]
local wallet_word = [[/^wallet$/{words}]]
local broken_unicode = [[has_flag(bad_unicode)]]

reconf['LEAKED_PASSWORD_SCAM'] = {
  re = string.format('%s & (%s | %s | %s | %s | %s | %s | lua:check_data_images)',
      btc_wallet_address, password_in_words, wallet_word,
      my_victim, your_webcam, your_onan, broken_unicode),
  description = 'Contains password word and BTC wallet address',
  functions = {
    check_data_images = function(task)
      local tp = task:get_text_parts() or {}

      for _,p in ipairs(tp) do
        if p:is_html() then
          local hc = p:get_html()

          if hc and hc:has_property('data_urls') then
            return true
          end
        end
      end

      return false
    end
  },
  score = 7.0,
  group = 'scams'
}
