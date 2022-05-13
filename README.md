# R_options_spread_strat

<div id="top"></div>


<br />

<h3 align="center">R_options_spread_strat</h3>

  <p align="center">
    Backtesting RSI, SMI, 100SMA options strategy
    <br />
    <a href="https://github.com/SomexJames/R_options_spread_strat"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/SomexJames/R_options_spread_strat/issues">Report Issues</a>
    ·
    <a href="https://github.com/SomexJames/R_options_spread_strat/issues">Submit Improvements</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#core-question">Core Question</a></li>
        <li><a href="#um-what">Um... What?</a></li>
      </ul>
    </li>
    <li>
      <a href="#problems-i-faced">Problems I Faced</a>
      <ul>
        <li><a href="#no-exit-strategy">No Exit "Strategy"</a></li>
        <li><a href="#varying-expiry-dates">Varying Expiry Dates</a></li>
        <li><a href="#strike-price-interval">Strike Price Interval</a></li>
        <li><a href="#stock-splits">Stock Splits</a></li>
        <li><a href="#specific-stock-split-scenario">Specific Stock Split Scenario</a></li>
      </ul>
    </li>
    <li><a href="#calculating-winrate">Calculating Winrate</a></li>
    <li>
      <a href="#pitfallsdeficiencies-and-possible-solutions">Pitfalls/Deficiencies and Possible Solutions</a>
      <ul>
        <li>
          <a href="#invalid-strike-price-intervals">Invalid Strike Price Intervals</a>
          <ul><a href="#potential-solution">Potential Solution</a></ul>
        </li>
        <li>
          <a href="#arbitrary-factor-selection">Arbitrary Factor Selection</a>
          <ul><a href="#potential-solution-1">Potential Solution</a></ul>
        </li>
      </ul>
    </li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

### Core Question
"If a stock's RSI is at or below 35, SMI is at or below -20, and the close price is at or above its 100-Day SMA, what is the likelihood that the stock's closing price 22-28 trading days from now will be above the open of tomorrow's price?"

### Um... What?
Yes, this may be a weird and oddly-specific question but hear me out:

I generally like to trade credit spreads with a 4-5 week expiry whenever I see the stock drop 5-10% from its most recent high. With such a broad criteria, you can guess what my win rate looks like with that. So, I cracked opened the Google textbook and researched as many "high accuracy technical indicators" as I could. Filtering out the many click-bait articles and videos, I just picked RSI and SMI as the indicators and tacked on the 100-day SMA just because I heard it's good for price to be above the SMA in a video (not the smartest reasoning, I know). Now it was time to test what my win rate would've looked like if I used this strategy for the past 20+ years.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- Problems I Faced -->
## Problems I Faced

### No Exit "Strategy"
Most sample trading strategies I found online were for trading a stock itself, not its options. So, they would exit their position once another signal or condition has been met. But that would create too many variables in trying to determine the profits of a spread. ("What expiry date do I pick?", "What if the sell condition doesn't occur until after the expiry date?", etc.) Then I remembered a tastytrades video that said theta starts to decay faster around 45 days until expiration date. So, since my data doesn't count weekends, I chose the first expiration date closest to 5 weeks out.

### Varying Expiry Dates
 If you've traded options before, you'd know that picking an expiration date that's specifically (x) number of days out should be useless. With most stocks offering expiration dates only on Fridays, frequency decreasing the further out you go, you're not guaranteed to get an expiration date exactly (x) number of days out. So, my solution was to get the closing price of the closest Friday from exactly 5 weeks out from the signal date.

***EDIT:*** I remember the math made sense in my head at the time, but now that I'm trying to explain it, I realize 22-28 trading days is wrong. It should be plus or minus 2 from 25 = 23-27. I guess this is why it helps to work on your docs during the project.

### Strike Price Interval
Since strike prices are standardized by exchanges, the strike price intervals aren’t guaranteed to be the same all the time. For example, I’ve seen AAPL’s strike price intervals vary between $1, $1.25, $2.5, $3, and $5 within the span of two years. And since my strategy is contingent upon the close price staying above the strike price, the availability of certain strike prices would have a significant factor in calculating win percentage. However, I decided to go with a very conservative approach of $5 intervals so that I can have the highest chance of having that strike price available if I were to implement this strategy.

### Stock Splits
Since I’m backtesting to see what would happen if I bought a stock option at that time, I can’t use the adjusted prices for calculation. For example, since most sources adjust historical prices for stock splits, that would mean my data would list AAPL’s price in early 2000s to be ~$1, leading my short option’s strike price to be $5. That would require AAPL to increase by more than 400% to be deemed profitable. Which, in implementation, wouldn’t be the case. So, I pulled the stock’s split history and adjusted the prices accordingly (along with some of the technical indicators) to reflect the price it would have traded for at the time.

### Specific Stock Split Scenario
In the cases in which a signal occurs, and a stock split occurs between the signal date and the option’s expiry date, I would have to use the strike price adjusted for the split to calculate returns since after the split, the stock has to close above a new strike price now.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- Calculating Winrate -->
## Calculating Winrate
Staying conservative, a win occurs if the stock price closes above the strike price on ALL DAYS between 22-28 days out. This way, I can be sure that I get the full credit of the spread at expiration no matter what day of the week the signal occurs.

<!-- Pitfalls/Deficiencies and Possible Solutions -->
## Pitfalls/Deficiencies and Possible Solutions
***NOTE:*** Not that this is the only reason why you shouldn’t apply this strategy in real-life, but I should make it clear that there are so many problems with this backtesting algorithm, that it should only be used for educational purposes.

### Invalid Strike Price Intervals
One of the glaring signs I saw that made me realize I’d have to take my results with more that grain of salt was that I’m using a fixed price interval, when price intervals vary quite frequently, even on a single stock. In addition, assuming strike price intervals of $5 is pretty high for most stocks considering what I’ve seen in my, albeit limited, options trading experience.

#### Potential Solution
I couldn’t find the exact mathematical formulas (if any) that exchanges like NYSE and CBOE used in determining strike price intervals. But, I could run some type of regression analysis to see what variables factor most in determining intervals (I assume it’ll be price and volume) and try and get a better idea of what intervals I might see at the given time. Or, if there’s a good resource that has stock option data in the form that I want, I can just use that, given it’s easy to implement.

### Arbitrary Factor Selection
The main factors that my strategy relies on were chosen with little to no mathematical or statistical reasoning. For example, the option expiry date was just because I remembered one statement from a video, and the basis of which I can barely explain with my own words. So, although I’m looking for a consistent strategy, this displays results more likely due to chance than my factor selection. In addition, my selection of RSI and SMI was again just based on some videos and articles without fully understanding why. Now that I’ve learned the intuition and calculation behind RSI and SMI, I realize that these two indicators together on top of the condition values I chose for them may not be as useful in my reversal-based strategy as I thought. I just saw that RSI and SMI give you overbought and oversold indicators, so I thought if I combine the two, that they’d reinforce the signal and give me a higher likelihood that the stock is destined for a reversal. However, after I learned how SMI was actually calculated, it may just as well be a trend indicator as a reversal indicator.

#### Potential Solution
Make sure I fully understand the indicators, especially how they’re calculated, to be able to fine tune accordingly and, of course, to make sure their purpose is what I’m looking for. As for the expiration dates, I will have to do more research on the greeks so that I can obtain more mathematical reasoning and error-explaining for my selections.

<p align="right">(<a href="#top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/github_username/repo_name.svg?style=for-the-badge
[contributors-url]: https://github.com/github_username/repo_name/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/github_username/repo_name.svg?style=for-the-badge
[forks-url]: https://github.com/github_username/repo_name/network/members
[stars-shield]: https://img.shields.io/github/stars/github_username/repo_name.svg?style=for-the-badge
[stars-url]: https://github.com/github_username/repo_name/stargazers
[issues-shield]: https://img.shields.io/github/issues/github_username/repo_name.svg?style=for-the-badge
[issues-url]: https://github.com/github_username/repo_name/issues
[license-shield]: https://img.shields.io/github/license/github_username/repo_name.svg?style=for-the-badge
[license-url]: https://github.com/github_username/repo_name/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
