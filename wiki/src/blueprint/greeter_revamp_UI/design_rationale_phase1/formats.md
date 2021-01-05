[[!tag archived]]

The **Formats** option allows users to choose which unit system (metric
or imperial), paper size, and date and time format to use according to
the standards in use in a territory.

We decided to call this option **Formats** which is how it is named in
*GNOME Settings* and close to how it is named in the
[Windows installer](https://edwardvbs.files.wordpress.com/2014/08/install1.png).

For example, the USA and United Kingdom, two English-speaking countries,
have different standards:

<table>
<tr><td></td><td>USA</td><td>United Kingdom</td></tr>
<tr><td>Unit system</td><td>Imperial</td><td>Metric</td></tr>
<tr><td>Paper size</td><td>Letter</td><td>A4</td></tr>
<tr><td>Date & time</td><td>3/17/2017 3:56 PM</td><td>17/03/2017 15:56</td></tr>
<tr><td>First day of the week</td><td>Sunday</td><td>Monday</td></tr>
</table>

We want to take into account people travelling or living in a territory
in which they prefer to have the interface in their own language rather
than the territory's language but want to use the local formats. *For
example, a Chinese person travelling to the US for business might prefer
Tails in Chinese but Sunday as the first day of the week to coordinate
with her clients.*

That's why we decided to have this option in the Greeter for more user control,
like configured usually in the installation of operating systems (like
[Debian](https://media.if-not-true-then-false.com/2012/08/03-debian-select-your-location-560x420.png)
and Windows).

Now, this flexibility can also lead to confusion. *For example, a French person
traveling to Japan for business might want Sunday as the first day of the week
to coordinate with her clients but might not be able to read the [names of the
days in Japanese](https://labs.riseup.net/code/attachments/download/1538/formats-implemented-session-fr-jp.png).*

In Windows, these problems are solved by having [very fine-grained
settings](https://labs.riseup.net/code/attachments/download/1568/French%20in%20the%20USA.png)
for each of the settings and allowing to change them in the session without
restarting.

Unfortunately, *GNOME Settings* doesn't have this:

  - Formats can only be changed [all at once](https://labs.riseup.net/code/attachments/download/1570/GNOME%20all%20at%20once.png).
  - Changing the formats requires [restarting](https://labs.riseup.net/code/attachments/download/1571/GNOME%20restart.png).

So, the confusion experienced by the French person choosing Japanese
formats cannot be corrected from inside the session in GNOME.

Still, we believe that:

  - Having that flexibility is worth it and allowed by most other
    operating systems.
  - Tails is an operating that is meant to be restarted quite often
    (let's say at least once a day), and in the rares scenarios where
    explicitly setting a format leads to confusion:
    - the confusion would be annoying but not critical
    - the user would likely learn from her mistake and not set the format the next day.

Ideally, the limitations of *GNOME Settings* would not exist but as of
now we still prefer offering flexibility in the Greeter and a simple
model similar to the one of Windows and GNOME. Even if we are conscious that it
might lead to confusion in some cases, we prefer that to having no flexibility
or having a more complex model as discussed in [February
2017](https://mailman.boum.org/pipermail/tails-ux/2017-February/003339.html).
