# React to a merge request note (available: thumbsup, thumbsdown, smile, tada, confused, heart, rocket, eyes)
glab api projects/:id/merge_requests/<number>/notes/<note_id>/award_emoji -X POST -F name=<emoji>
