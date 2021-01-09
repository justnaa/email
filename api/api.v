module api 

import vweb
import settings
import os
import json

const (
	port = 80 
)

struct Email {
    from string
    to []string
    data string
}

struct Emails {
    id []string [json:files]
}

struct App {
	vweb.Context 
}

pub fn start() {
	vweb.run<App>(port)
    println('API Started')
}

pub fn (mut app App) init_once() {
}

pub fn (mut app App) init() {
}

pub fn (mut app App) index() vweb.Result {
    return app.text('API is up')
}

// Sees if the string is safe (if it includes '/', '../', '~', etc)
fn safe_string(str string) bool {
    // Checking if the string is safe unurl encoded
    if '/' in str {
        return false
    }
    if '../' in str {
        return false
    }
    if '~' in str {
        return false
    }
    if '%2F' in str {
        return false
    }
    if '%2f' in str {
        return false
    }
    if '..%2f' in str {
        return false
    }
    if '..%2F' in str {
        return false
    }
    return true
} 

// TODO: make this stronger
fn authentication(key string) bool {
    // loading settings
    settingsjson := settings.load()
    if key == settingsjson.api_key {
        return true
    } else {
        return false
    }
}

pub fn (mut app App) email() vweb.Result {
    // Getting id
    mut id := app.query["id"]
    // Replacing spaces
    id = id.replace('%20', ' ')
    // Seeing if id is safe
    if safe_string(id) {} else {
        return app.json('{"error": "string is unsafe!"}')
    }
    // Getting auth key
    auth := app.query["auth"]
    if !authentication(auth) {
       return app.json('{"error":"Please authenticate"}')
    }
    // Seeing if theres an id
    if id.len > 0 {
    } else {
        return app.json('{"error":"id query is needed"}')
    }
    // Getting settings
    settingsjson := settings.load()
    // Getting email
    email_contents := os.read_file('${settingsjson.email_dir}/$id') or {
       return app.json('{"error":"unable to get file"}')
    } 
    // Parsing as json
    as_json := json.decode(Email, email_contents) or {
        return app.json('{"error":"unable to parse email"}')
    }
    // returning
    encoded := json.encode(as_json)
    return app.json(encoded)
}

pub fn (mut app App) emails() vweb.Result {
    // Getting auth key
    auth := app.query["auth"]
    // Seeing if theyre authenticated
    if !authentication(auth) {
        return app.json('{"error":"Please authenticate"}')
   } 
   // Getting settings
   settingsjson := settings.load()
   // Getting emails
   emails_contents := os.read_file('${settingsjson.email_dir}/emails.json') or {
        return app.json('{"error":"unable to get file"}')
   }
   // Parsing
   as_json := json.decode(Emails, emails_contents) or {
        return app.json('{"error":"unable to parse email"}')
   }
   // returning
   encoded := json.encode(as_json)
   return app.json(encoded)
}




