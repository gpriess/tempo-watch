# Tempo
An iOS/Apple Watch app that builds playlists to match your heart rate.
### Built for [MHacks 6](http://mhacks.org)

## Inspiration
Our team has a strong background with OSX development, back-end web dev, and graphic design. We initially thought we'd come up with a classic iOS app + hackathon RESTful back end. After brainstorming, however, we realized two of our team members had Apple Watches and have never developed on them. We used this Hackathon as an opportunity to learn about iOS9, test the limits of the Apple Watch framework, and explore its potential for future software.

## What it does
Tempo uses your Apple Watch's heart rate sensor to match your heart rate to similarly-paced songs. If you spend your lazy morning at home, our app constructs a playlist of similarly-lazy music at, let's say, 80bpm. If you decide to thrown on your running shoes and raise your heart rate with some healthy exercise, Tempo wipes the playlist and instantly starts selecting music to fit your activity level.

## How we built it
First, we collect heart rate information using Apple's Health Kit Library
Then we got data collection working with the super awesome music metadata API, [Echo Nest](http://developer.echonest.com/).
Once we had an algorithm that turned heart rate into a list of potential songs, we used the [Spotify API](https://developer.spotify.com/web-api/)/[iOS SDK](https://developer.spotify.com/technologies/spotify-ios-sdk/) to stream music to our iPhones.

## Accomplishments we're proud of
- Good music
- Background streaming support
- Two-way iOS/Apple Watch music controls
- Custom graphics

## What we learned
``` Objective-C is not C. ```

``` Let's just read the documentation. ```

``` Sleep? Sleep. ```

## What's next?
A released version in the App Store!