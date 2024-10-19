



function Find-wsBitLockerKey {
    param ()

        If (-not(Get-module -ListAvailable -name Microsoft.Graph)) {
        write-host "MSOnline module is missing."
        write-host "Run from elevated PS: Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force"
        break
    }
    If (-not(Get-module -ListAvailable -name ActiveDirectory)) {
        write-host "ActiveDirectory module is missing."
        write-host "Run from elevated PS: Install-Module ActiveDirectory -force"
        break
    }

    #Define MBAM
    $mbamUrl = "https://ws-mbam.wetter.wetterssource.com/MBAMAdministrationService/AdministrationService.svc"

    # Define the SCCM Site Server and Site Code
    $SCCMServer = "WS-CM1.wetter.wetterssource.com"
    $SCCMSQLServer = "WS-CM1.wetter.wetterssource.com"
    $SiteCode = "WS1"
    $CmDatabase = "CM_$SiteCode"

    # Decide which sources you will search for the key at.
    $SourcesEnabled = @{
        Mbam = $true
        AD = $true
        CM = $true
        MeId = $true    
    }

    #region Make logo image for page  see https://wetterssource.com/ondemandtoast [Update Images] for more details
    $LogoImage = "${Env:Temp}\MMSFFL.png"
    $B64Logo = @'
iVBORw0KGgoAAAANSUhEUgAAAFQAAABUCAYAAAAcaxDBAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAEnQAABJ0Ad5mH3gAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAEAmlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4wLWMwMDAgNzkuZGE0YTdlNWVmLCAyMDIyLzExLzIyLTEzOjUwOjA3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InV1aWQ6NUQyMDg5MjQ5M0JGREIxMTkxNEE4NTkwRDMxNTA4QzgiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6MkE2MjQ4MDg4OTdGMTFFRThBOEQ5MzJGM0NCNjI2QUIiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MkE2MjQ4MDc4OTdG
MTFFRThBOEQ5MzJGM0NCNjI2QUIiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgSWxsdXN0cmF0b3IgMjguMCAoTWFjaW50b3NoKSI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ1dWlkOjJlY2I2ZTE1LWExNDAtZjk0Ny05ZjkzLTE4MmYxOTQwYjM4YyIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpjYmFjYzU1OC0xMjZiLTRkZTEtYjkxZi0xZGY2YWI2YmI4OGEiLz4gPGRjOnRpdGxlPiA8cmRmOkFsdD4gPHJkZjpsaSB4bWw6bGFuZz0ieC1kZWZhdWx0Ij5NTVNGVExfMjAyNF8yMDB4MjAwPC9yZGY6bGk+IDwvcmRmOkFsdD4gPC9kYzp0aXRsZT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6C9+0pAAA9yUlEQVR4XtW9B6AeZZ0u/szM1+vp/ZyUk56QBBKQIgmIqwIWQMoiIiy2tWyxsahXN6tc/7aruKx3LXvV66rrih0sNDEghhYgBAjpJ+fk9PJ95+t15v8873cSA4L+XXe99//Cm5nvnZm3PO/zazPvzLGW//QZr1T3YzCcQp8/hwdzPZitheHCguvaqMGBazsIl8vAkQmkZrJ4rV3F+4NV1H2A63hwfB58fheO34NtufDxd9eSJBLtYdT4u8w8N5VBMVXCt3LtuGkuhqwLBKM+BHy8zrbgCzkIOBZsrwYfz7fqdZO9SgWVQgV+BwiHLUQjFkJBC16tjpnJMsIhoFZ3sf9IGZ/Me3hjrYbCohY0veks+FuieL5UPzoJd2ISdlsT7L4eWD4OROUje1F59DZY/jIsJwCvGIenQcIzx03SLvuurVetINyxGCNL+vFvu/ailJuB03XVO7Y5toepSgR7S62oEkBHZ1uWyfwXruchzwY6OptxWkcA
E/kKWosFdAVc1II8gUB6zHW7Dl6Mlu4Qmrsi7Bhgc/D+gIViOodgrYzW5hK8cAmTFQepkg3LdeG36ghGAgSzbsD0qWm3xsz6mNUfP8flY92JhI0w2/RbHpIxC5VSHeNzdazg77ex28mKh0IsiOjJ/XCi6txvJzsRg9PTCbspCcu2F0pZHo7Cm9kPVLP8FWd2CDYnl203th6BJprcwlclicJwWpdiRyqFQmYYL2rNwhajyEUEnTqiZJ5P8BNITYKmgfzkALklc0bKHnqW9uC/X7kOA6f1wSMBXDKzzMaqzP6ojY6BKDoWxdk5myCzBgKqjiQrJQQJTthzsbkpi2uXTeDcnhQCbgWlAoEjs3ycWJvtCUztO2yXtbCTHgJ+sphjD3IbDnGSNDgea05aSLZaGOQktLPHZbK8mCqiMpUzI3ihlJsvYWwohRLJcTz5Q7DizdzxwXMIZpD9ImmsQB02MwKc5CB/UzrtEMcb68ZkuYLpuXE0sY8UZTjNbyBDWYXnsUcUPZuyFbRddtXCvBtAkZUTYf5rccweDmTquGh5E169oR2JagFxNpJsCaK1LYiungiaKeZWkDBoVslMm6LslShCEymyisCzsQNkfJUdXRIrI4oyMjUfSvCToZxYXuNV2HHuC0xtPeZQgOMV4wl4OOAhRImoVuqoll0UKi42sfsbq+xqzUKhVEOV40+s6jDjOTGlJ7J4+tdH8NAde/HQvYcxOZVH39IWBIPqMCvJUh1kJihdvI6TZlOlGVZqK2ZyazuU40AXPLsHD81OI12awyDH0uJn+TmvvWbbpD8oqhrdMDOcxpLUED7YvQdbQtNwatR/XghpBM2sVTiANMXqgoEQmmIOouV5JJoCiDcHEIgssJJ9kbhbZCdChGByHu5sFuqzy8naxYk5UiSTSmSbVUVbqEZ97SFX4QSQhj5IfxJQgcpJAPf91ANhglolWJVynW2zfk5Mif0pUXI25V2cXJA+tVClGM9PZpCfK8IK+1GvupgdmsPe+4fw6B378Myu
MczxWI71DI9lyfAo+heRmZq83AS8/BhBZB+MqC8Aqq1dI6DMwXaSeQWmskX8anIONcNOTjDH5Xz4Fa/aNhYKQ6Cmnh5D6vERTI2W0FtP4z09+3FVaAgvrk2h0y0h4wUwbUdxqAj8GXXpkjYar/w8FXfBiLZHcTNAcuAWRdOi0eFoUT80SVDqBpRU1cP2gocxDr7AeubLvI7ARDnrAa+KCgGpuQRWqq1OphpZoeFin0NB7XvIzHNQvCYeJsBkZ7rgYgWLNrC+Ohkqsa+Sbemj8xh7ehLDBPDgzqMYPTiDXEHGlFKj2Q35kCfLa5aDVWs6Kd3TQCXPFqgG6ikDKqjK4GM/BCSvs0K9JM5qkgHYNzbKnuXQFymhxSkjLsP8pksv2RajUdjjRDE5TCbliqj6A3hgKoGjOT/+rDmDZU4K59UmcEF1Eu0E9qlajPojhvPafbTO1LrFWVmJBoiGmTQ2EdGxjvp+zngqz5nlsaqF/Rz0PQUOtkR2FWlA2Pd8zUbFdWATwECdE0BG0fQTUQJIoyVdSgrTI5AOJZOzdRTyZBCP+zngPCWmN+dhAxnucjJKBLOmTIkqUfYLxRpIYtQpxnbAoS52DOCcS5ZbyHGSVw760JyYZzvsZ7iZAFLMZGQl+jQ+VrCNYA7CH1lCdWJj95FJHEoXMMp+c04MYRzW6Vxx5WXbYrTt4/4I0m2tSHQlEOtrgr+7GQ/XOzBUT2AFFXCnW0WSOvPsyhTWldI4TJZsoKKONzdxpjl7VpGGiJqWOlO60y2UUTsw0RB3tlet2KhzVn9NUb+f2wq9MIFZILBlsoqSbEAV4+walT7BbfBRepP/kpFiaoyu0/y8C5egZ3LUuQQ5w/0QwTyTE+UjIAUOrMqzq1RjNU5Mldlm9kkVEMAx1qU+sRQFmV2rjMH+LHp6CZwOSNYjbRxXB4GkNxDqo7fSCyfcxMmr4sGDk5iaS7MODzG7jKWBAjqIRUiG9IqrLtsWpG6Ytv04wgsiiRAC8RDCyTDCbXE8QeV7j9eH
w0iiiXqit1pFXy6D9slJNB0+Cv9omkaE3fdJgVWpg0pwx1Nwh6ZQn81T/dmUekJCELPMPyRD93JbJ1uLygS1xG2JLJGA0x4RYJGb1lSg1gUpB8/OSlVF6AkV6BUUqDOJC/fpA5P9h/h7kJM2yEnJE1DZ7qolE2ZTeMhC/r6fdf6Ifb2XYxjmWDoIXNBvo29RkcawgNamqBm3UTPyMBwayoDYGaD+9HA0lcM9z8xgbCaDrrAMHyeG/nCAOp9+ASIks3Pl1Zds81FsxqwQDthxViTnmgNmgw7FTL7fuBXF/XYn7nJ6cJT+Y28+R2ArsDhwZyKD2uEMwcwSTLKRxsCby6FOhV+pOyjT8NBjgo8j3MXt95jzZJOAK9EqG3ZSZMsEVJJepQ6tULlrIujdmg5XKLJ+Dlx205Gfyj4dHa+jOU62zVCXUmdPcT4PEbW1ZGEHT6xzHBpLnvA8zHH8Gxu8g+I/RjWU50xMEtyyZ+P0Xhe9fbQPNG5TDDyCQYdSQCDVmLwSunOjdMMeoYt13/4UJkmYgUgNzdKvnPlOeimd/hoSVEW0v7B+fOc3vSARvs/qxL/PtyHPnjnUG4FmOr+RkDEQdZrtEucgSye6xEq21lL40MwerC0UaEwicLPUmR20xMvIUA6iTuUk1lUp1sQdAQIn8f4Mf9/NY/QuDJCUbmOE5OIoe7JEZJXHwfip6/zSxQRDlj+W8Bu1GqTiT9L/fXwPLX3cA+MLtkGWkrmTMxZWkq2vIPgtrGeCxNhJ3babdVBdPzuxvR5e/3drPLTSuBXVb1p5H9ttTVJCQ37jMaRpxGZzFWRKDGLI9hZa+8FgGUnWW56rIuGVEfFTf7K8LpG/6k0XGYYOO3Fsf6aKqUdGkRmdR2ZsHg4VVKQ5Sh1D1pJmIfZeYeKeYBP2+xI4NTtHb4D6jNbfLfjhsYM1VlymnhQrBSajOKoE4BYy9QfMdYJZEZiNCW4ASmCNu6NMdpZ5DvtLsScKNCAWwyTyxfjBNZZxzCjSyqTToCGhBNEm
1nkthQozrOtB7mxnvx6myzdKNrKZZyeeIwBWdpBdYY8BB/1g6tY6x1bmtXPFKibmy5jIlpFmZ2TQNJvyYpI+Sgbx0viKtCOOXC0eLlOi8uyDc/VbXr1N4eIT9WaM2gk6rAw9CaRsbCAeRKiVUQ8tiF3IE1gyhtnHTu4PJAwQ52fmEHOoQQo+Y3gqIbohBJB6noYC9C2B7xDIr0vUBZRAJOsNqNwaMI0UnJBZJkuvewge5ZtSZ/SaAHXZablZHBtmCWSArpTApLCQ2ey0kD+WTtw/IVEZoD9ZQVuELhSBaKL9oGZBif2QHpe68AigpRiYDbkEWgZO3kYzLX+CgJYY4JQy1PMsN2qS15Vo/Z3r3v7KbXNUq9uLHXDDEbT1xJDoiSM50IJIe5x+LMPAQs7Mgkd/jVUYHSvxPOALozibQSv1UwvVQrTAWWQEVKHukX/5KIH8GvP3CG6OKoA9RZmNVrhP8iwAaS9sSRzuy9CYxnx0yDl5NelWZvbbDLrOEwUsx4B5emMF+T4Cm3Wwa78/8bwkvZLeeNVMJlU9kjbdP0JS5O8KJ7RKkM2k83TOu5FQuWHUQGRnHTGKXG2uDo/GNsAydg+TVZuhOSVp++4veD/L9GF7rtt02uMgNJCqXAe26CtkjW9XZGhYIRglAlelJa1zVvPSrU8ewJKZWaygJVzG8+JxdqO5hCEanme4Oyl2qVcEs0Iw1NnfgCkQJaoNcTVAKsnqkJ0NdBvJIVsEotxDRUgB+rv0zFAToPyfhY0Tf1diOz5GPX1xhry6ocMiqe1l1JeD4RCZSLarWWYxk/wxHpR8bAohOunc99klxOnNpA5RUjm+AHW6gJ/m+J5hXG19+pFbvDvme0l36SnODlmiWyTqnzcxiXlGG/VgGE4TPYBElGGW3xiUKoP1mhNA+qnDqA9P0J+hZudAZZv7mssm1pZYM2YwImkMDwcklmmCJNoC0WS228COyOi2kpA7AUyT9NMAx11OiAyUip572gslnWazzWbqoQStpE3SSITl
DtFtpq8dRCtVHTkDl5Nn1If0igBml2yKeh9ptYIGKcFxTR2miiNZ6gzhKCgYpdQdEKAX/uI+r6wrmKRPygRTM5ms5VCh3zUxXkJqtoxingqY5jUyoNteCYoGmcrWsk8Po3Rk3AAqgxWNRbBucRKDzWQx65E+FCMFXH2Bld7CVuio3IBiBiBqaMcc/E9PuukTo4tj5oX/SCJ1V6vETmZS8whlC9DtBzNbBEpGqk5GVKlZAxTz1b4qBmMkSs4h0fzwi9HM0+zuMEW+jbrVACpeUS1Rb+jmnYU2N0dXp0SR9tNdCiBPn2N6NIfJg3OGafHBHoQGuqhXfJh7YgilkSk40RD62pO49JQ+vMZj7J+eMnpW9Sk9H+GOJ/3QCP+Lkwlh1cwJjdv0S91QGE92L8atI2kcHBrnGOkGSdwJFmnArnnoplewgq7ZEkaNTpaAzpKhqov2glG/qTtFolivueeXnku2lZnrBLaLMUXULaJQ99F386FAGpfI3CqBTc2VMPrUFPKpAuLLehFe2ovZJ8nQ0RmE4hFc/uIV+GTmMXR+6WaUp1Oc/gbzjyd2QGNawPjZ6TjiJ474OaP/vek555tJ4u+Fosbm2Y178nOpQ/wXXoAfX/Ym3PzEOIbGpsjehnsmdU5fH4PU2asCtPJkYTXFSKJAf5X+pyK4SUqix/PvKlJVXnLPPV5V4svcw/CxnYDmaj6k6UvOM5xzAyFabR+tIc+hzszm6hjdPY7cDJ36pV0ozuVRSefR1JLAtpevwDu/8CFkf3Y7qnHG+HREbYZ5RiVyIF5ANzWZj4GnsUnmSyXDFCVZVEQiUryNclMqvcYR0fAtVPabVGHEpqhNxSz3AqSRzjM6Rj4a9SX9OEu/dY5cMT99ZtUn0eaFHn2uBAkx8k9fwrZSMx7cdZDNMzoTS5mTPG2A2256MH3cT2T8aKVdiFItzBPIOVacYfWPk7LO6r+4dluNGnhxKM8gPyeflxrDMXrz8NNpFDJVxrchWjsymHrBoUVUFFXMUCWMp1nG
K6jgk7EwXjbYgvUP/QK1iQl4wRD8g0sR3rAegWVLERjog5cvwFXcTwOg5zgN/w0Ir1uF4MaT4F+6BFZ3F9xMFnZLM4KnnILgskEElg/SyrL9+exvrhX7CXqwpwvhUzchsGQJnCWLjc+IYpGDqBFXBibr1sB62ctRfclLYJ16KoK9PYZxHttweb0VZqzOumwaw8qfvRy/dppwYHSWBlUBC+dFk8ZtM/MAq15Mae0u+dHF/VayM8IxTFPU53g8xLZJYNI5ksfqSBZlujolMtFH5d3cFEDvQBTpLGnNhm3SvcrZqNHnDEcDaFvWgbFdR0kAdkrRDBswicrHo/nzU4HXr/hz3HvexTjEDvY2hXH2HbcgcNNnUZHTzPPsXA6hzadg/7aPM6qJUMwsnG7nsegd16G+YQP2fuC/47HRDHycxBdP7kPvh25gaDwNKxYzoIUiQWTfez1+teYMzE1nsIq+88avfR7ezTcjuHQxSm99O3598hY8WQ9hlsY2SNFurxfo3uWwdv9uxG77IWq7nyRqRIHei1xGeSDiiGyF3Dmp0W7+0875i9O6Ozwe4DZC8NpZztGaO1x0auj0s5o+fxGnN2foSlDZ0l2Q3vBzXqL0gvqXxLBkVZKWm9GT9IxuTDBLPKNNjHebIxJkoxePA7qQAmyw4A/h+6NlfPS+EWx7aAa/3PIaRLecBTubMU8zw3TFZq99Mz6fb8E/bB/GZ55I4Sk6y2EyywkGsSNr41OPzeDvt4/gK01rUH3dVQjqDhSv9ZVL8L3mIvx41dn4yL0j+NjOKfxsqq4QHVEayMLfvBtf23I5PrmvhJ1TDJsZ88qzeLwawnfqbdhx2XXwXX6ZuVWoyEtJ/zbAlJsnB78RHmcJYJHZhL5lB/4abQ1PduhjTXBfYCZ5bYI12BvsNBJ0To17UyKzCFiQFs1Hd0FmSq6ByvS4N0i1E+DVPo/l1B+BkHxXJh436Rio6pn2qT/zuQJm5rJ4cs8RfJXu6qErr0OsoxU+xo3WxRfjh0tOxe07
nsHYZArpVAbVQrFRDaWilM8jxbKR4Ul8/9Fh3HnWKxHdygkZH0P0pNV49DWvx789PoaDhyYYhmZRmM/BLhbgP+Vk7Dh5K77z64Nopbtz/cxOvOvWf8bfbP8m3jO5E5cPBLHq8JOo/+vXjVjLuz/edf6WxyMwBar2CYeR/RpB9VHk+/izSCDvYag9zW2Ex8TSkBidoHhr9AIzk64QQBch1mBuVBMo/VbAOTsyj5mhNMMt2nvqfN1G03NzqSyJ6nGGqvGFpF050H4aCZoGPPjUCG7pPAm1V74KTRtWY+f5V+B7z8xiKpU3+lR+rIzXicknw8EBH6En8a0ZBwde+3q0LF+EucuvwrcrSTx9aJJ1s686j0l9qXd2YZheyvRcBj2Uoo37diL+L19A5MZ/wOLr/wpbbnwflnx8G6q7n6YBo042Vzb6a/QmwZHPXGX2CKoCE2UfGdlKQKfZxu2E7WmWJfhb/juVN3llww6FuENZUEQjcRc7A2RlgED6GaZpX8yUIp8bTuPo7kladT0LpXiVacXZGx46bo2fLyXDflyxqQ8vXtSEH9PtunPLxRj6wEfwFfpyFi35tWcswaqOOM9UrPabpF9+NrB1sA1XvWgxDh2dwb8GF2Py4zfhOwOn4dH9E7hoYx9esaqDEsRxcKBaQ2Cl5tDPcfV3JvHA4Tn8z7Mux57/8c8ovvd9cF90Ouxf3Y/67XcafW9izxOS9KYJQAiYVIQBlWUBIi1BHGO+jVg9wWPklWFniiwV4HpiYiu41/2taMhCV5sDjt3Eu0GJtJQuFaSY2rMoioHlSdTyZUzsnTa392gKDaAN51L5OYlF7Ava6RW8tzWPj3UX0BUP4FMjwJun2/DUTAnXLQrgo/EprO9haGsipUZq1Mj2ye5X9wbwidgELljahDuO5vEXqU58/XABmzvD+B+RUbyuw0OsWRNCEOiW1R7ZiTMevQdXnTmIzp42fDsXxYdaN+PGrdfi63/7MTz++a8Bf/3XCCVi8Dihx8VL/eUkEiO5841I
Tx0hULoTlSFD7+CWIQtGWd7PyyZ5uMB93UyxlW0iT8+eLoaNpri9wFCxlVuOT6A2jJGHHlr9PoJazVcwe2jOLIdxGO9qTtQnZbV/LAkQiXySIas9PIyV3/4XXLckBJeD3jc6hy0rOnHJzp8h8POfoamtCSE2aHzJheu1E43Q+HGIrV/jtaWDWDHYjd0HJ9HelsR17hjiX/0iDU4NTYkoIeAFFOEy9Xb0kx/Dld//Ij7cXcZfLItiRXMYE/QTvzFUwgfmmvHli9+B7F+/G0G6YfJKjiW1LbE3/TAspXFlFmAPk4XjLKdTxhCdbhPHO8WtfheYJfZy9M0jWqlSib6YKVClO43hYZZhkojLneruj6KlI0zdonls3JcUS/l/ozcLSbuNn6yDClm3But33YNz7vkBrjh1ABeevRZX5w8h/LX/ZW6ZaWCq67lJTxJ9dPSrw6NYRPCu7rbx0hevw7VLw1j9jS+idmgE/njMTP4xpslXLY/SAn5kG9a+81q87ov/gPft+Hdsyz2Ba3oYFaYz+N8PHMZdp5yHwGmbYeVzx6891u8GUxsMlWFKE9CnCNhSnraTQ9c2xfIcs5DIMGtayFCBSSZJR/CgVmLIbQqxg7qZIF2qLDDlLmmhVnt3iIZJzwx5HcFWmKZs+tTo17OSALcpugLO+epXcFH2MN5xcicWff2LKI6MwSJgqkuDaNxUOzGxlBXU6XsW7/klTr3je/ib8wZw7o6foXjn3ahHY8+aUIWSDOcYSp4P3/tvMA8QK9/4FgIf/m9Y/lfX4U13/ytevLjZPM45SGrVu7rNE9bjacGFOpakx/UE9QGKvZb7THEMVHYYpFge4alTzPPM+YV9rTQx7Dy2naYvJ1DpSy+IvSy+1IBcKYLNHInY5n6kAeqEbABlPc+bZCxiURTHKa7/8s9Y9rmPofLAg3DlpDcOGxE7cTzyD42PqGupJqoMIOzv3oK1/3gTAt/+lvEc9HiEJ5jzXE64TZ0YPOtMHHzPh/Dd1/0tdn7i88j//UdR
eeObUXoVjWHvMvNooykWxGCI/VZUp5udSmYAREp9OKEj4+yXj8fiVF8PkHjLeZoeixxkFojSozPcHuJ5uh1kogFbnebJ1ZKHelWWvQGmyTzBZO6LqbqpKUZp1d5xQBtt/95kNSVR/OV25L/8FROZmDu3DP3idPLb2pMIxSKNOSF40STLqCvD8agps8jGGiOl3GduQnVUzKbq4YFANIJm6uA49ahN4O2XbEGGYe9jkwV8MbgUnzj7KvzPq67H5964DTcuPRdjNQev3NiPrQceQe3hR+BGtOzRtMr+LPRJnGfljVKGmNzfyx9p/mrhof2EYZi/xVYBPs2tTxPk0okToGY9lAqZa5WGLtVNYgOo0akNUGWc6nr+ywb8VHpir7wCh0Abo/D7ktwU3aCQRWfnpaP0uHpLXxTXrG/HKoa8ZcZ9Hn3cTW0hvP6kDqxtoeXmJLKLBnxzA0UhrsSR5y2KWLhydSvOXZRg3TQSX/4q1n/873Fd8RDOb6KHQv+mbPuQ4wiXMcL7y9VJvG3fPWj5x0/TgOUbN7WPd507ql/3CrSV2DDNkjWHue1kkURc4IqdYyzTlu4uOrXe6vZ7vuHFmmj2eYFu/x8cZ8cZFfX2B5CjVcuUbGSrNvIMCQv0t0qug4MHCzhyqGCe9BVoOQuc8WRzEz5wzjJc/U8fRvGuXyAYj2D6vR/Ahxefi/F0AR+3DmPNje9HPk83RcvolEQv6i978WIE1q3VPRbUs3lUdzwIi/UFNm6ERf+yzuip+vBOuNnss1wrXSvW+k7ZCH8yCS2OqO7Zw7yXYWEV4f5eWKtXo9K/CCU6+0I7NDWO4IG9qD66C6ViyVyvZSzhUACTn/ocbqj149YdB1Ck7jUslU6WjiUJBHIbAZf/qaNBZj2e7uPOpqTIxiv+/Qff9NrZlq2FWDQ4o2nS284hSh9vrhZCkTFYliGWFieUCGyOqD+xp4xnDla4r/ultnnWlGyJ4yPnLMZbb74BuXvuQ5DiN/2+D+JDC4B+wiagH30OoCax
FyVah0KhQQihSnB0twi5HA0lxU6sjtPPFJiahGNJF5Ch5jxudcSjgdMdJAEhH9MqFnmZDce0SelivXJQzHkK+VRK8GIk5OhnPo93lftx+8OHUBGgql/9U81sV4GDfjU4y2Ews2c4u9nDEnr4kjZ7nkrgEM3V0IiH4aN63uzRZytgUSiHMEVZVI6FOSgOJm3Rl3NjOJCJ4Gg6hLmSHyWCKhEsFso4VGCla9Yg6lURnE/DqVbMgzk9qZQH8ezErnHAznwKfp7np9g5ZIBCSH82Az9B9vscArFQRtfGn5lvHDuW9VvllC5zHnNAdbFtHQ/UqvDTepoIqlKBy7DZRF8cS6BcalzPHEzNIjS4GMPJDhydzbG/nCQDphI7rn1mDeEYmEqK96UakyGqO25fQdVoffkr3/QqUqL8oXWOQR587YZp+poF3HWoBd98sgPlaAgOkXUDQSP6D96fxhQjlcYDmEZSHL66vxXvWZvA+U/fh0RuHrvWn4n3TcVhE6ibQiNY/dEbfsNQAhHcsB546Z/Rxmmd0m8h/qdJBE9QHVp3Gv6x2oHbHh/BXLZkwPu9iYC2hzyc3VnHOcTvKhZY//a//tVzaXzKAYo79WV7vIDrNh2ls5zHDT/vxSd+vpgUddHV7WD1uhiaWgN44L40xo8QGD0uPCGFyKTeriactLQTrZEADh+dxe4jU1izvBc3BY9ilQAtsLPVKqK06pOfuhnfH3wRRkZnKIYSqYWK/oRJ86g1ontHU9g7NIU0J1yO/P+nREATlN6ru2t4m1Mzt/SsL/3g596hsRSenKtjVzqMd24YxfVnDyPPyOANP1yB7+9uA8LUZ+R3KO5gYEkYU5MVpGeoY6SFn5N0t0drkXREd/PF3DNOWoTPhQjojdSv83nzANB5z3vwT1uvwpe378XkbN7c1DAX/R9IWj0tKZFRO1Gkf2/iyS0E9KaeEi701ZDxGOzc1LYJN0c24LYjEaRzZby4hcyjbpyeiWKIetL4UspBWviii31P5pFOEeDnAVPJ
dK5SQ5VZ+/y/IT48XVuLOiu69Wzcc+7FuOXxUYyMp5ErVlAoMWv7fyCXqFsNoOrnH5QsLCfR1tELKNBtrFr0z5+ux5BfthQ4eQ3OX1TFRrMgKYjhyQiND62gHpIYRJgUbL8AkMeTDi8o8Wcn/qY1jvV24fA1f4mvj9OXOzRujNazrvmvzsYPlm22jNvDkkb5H5p4jUzI2ZyQSLaGCiN5l8aYTp6cdKrD1T24ZGUAETlWWT92T0Xpg9KXoPV6VlLbf0D7ulpZVjZEDtSufgO+07YG9+8aIivlmpjT/jSJICwlE/+G0vAt6vKfUF9+l9sPFctYR73ecOKfM94XSjxtkVvDKbx2ZIaeUjCMR/qaOVdiHX22c2ujOK/KwKoYRDEbxMOTDMdU92/7O39QkvWuVOm8F+grnrMVd265CLc8OoKZuQzh/dOhqeDy7eUKfpyjT0yH/gr26Txa+Euo5z/M8h/R7XsnywNa1LoQHf3OxK6fWi4ijDr+pX8Vrl96Ju5f0k8b4pURpyN/3dR+tKUo7uUwxueCeDBFgZBk/JFJtmY+nYfX14+9f/5GfOFwFQcOT0CLbf8kiazspSK/mUz8HPMqdkhLxfUGXYXHGK9Aa++p9PBphrx/xUDAKjMcXVgn8LyJY0rS8d9IFZai0XU92oyRMnakWinQZ1y27XJ/Hn975BBjat2Ss3B3LoovTobNaog/ikS8VlXUyIb55jb8NB/C9iePMuKSvlk4578yEbAllL4vkHmXsc0igSwxS/dtrxbx2fIcbq3oNUQLA06QKsnCGgJ+f7WAUZHJob/MOo4nhaGK4BiGLubxdR5Br9Vx+pERLB4axQ9rYYay7/qBd3u7h7OqWeQDdOyDddzY042P7eFMjuV0y36htv940k1iLWIVXeUw1EXb/+rE9to4a/9Mxl1KjyNLFpYYOQXptm1HGe9yMjhIZkHvsPoj+GSgGVfbYRLKw6eIxfU2dWq8nUEIPR0lLRukn211dMDubEdzyI8WAhqtlLFmZhr2xAxu
qTNie9umS7Zdo7fTLD8ClPijoSBuXduOEqdx+ghjbI2dtP5jkoFPs0sg/xTENIldfgvdoXdRP2r9vB5ZkC8MIOr4YHUOD1oELNJE5dqGfDiGveTNSz1OAqe8TKBuq+ZQ1HIdAaq+6+noqtVwVgzC3xxHhdFjKh7FbFMMh7rbMNzfiSCDGvtqt4IJ3Yco0iHP+fAYT8qEXawd8NDTQyvPY/8pSQxV/lMkttNNdl6kdVX8Sc/abHWnKpxIIB6jidLNy1CiAWo4iT2hOB4mA4kexdmHxZKiGq+skmUCdvVq2ItkdFgP6/XXKojSgMXI0AD9UC/kQ7g9ATvNGRxh4Ryt3BFWt6vbT/+sjO4wqbxcd2lYw+/Qz/+3pi4CImNUl6jmKzQ0daNqgmE/1ib1hJUgUdwbelK35vwo604XcYxymxCgsvhyKwcGYPf2Hn8hTesUzPMv/uP5HUaGFvx6HV3Hj9I/HKc/OMEo6QEGo2NddcTdIqJuCesHquimfm0sNCftlf9/knT72SGY9aYI3HNWotpNNtJFsmKkC0Pj51rFGH8uVhGHqieYeblOYicl1urvk8MOLXvUS2a2XscM+hjz1BAuFehq6e1kp/GYf5RgpugCzFDBTPbY6NTbwQTTR3eqO1bC8l7OsCRBMy0Lp5kzAvR/d8roYRpz6UX92L6qiOyWXgSCfnLDxcFKicNo6HSTKccvok+6zhDGwhG3ikN6lMF9q7MLdlSrsz34aKBdghgYm8SKX+/EKT+/D5tvuxebfvorJJ8aMoJs5xl/JhM2Ui1akmLh1PkKVjOU8uerSGdq6IhXEdKL+C5BlA40oLLhP5U+/A+mI+zfE7qP2p1EsiWGaE8zwn4/JbGEfXoHR/03YShHTVAvIam6yFq9uParWhGzNYp7LAGru9vcoEY2g+r+Qyg+9hT8v34MS+59CJ1PPIPk/iPo2r0fgXt3Y3rvOOyuZh8qYQ/PBHyYpj9rseJYzkPTtIWZSbKeMxfVq3BSLuqEZlSgLlhtY7a1VTq2
f2KZ0ollJ+Zj6cT954iiSeb8E/aPpWP1qOg55XqB6+exAGqtCbxk81n0PRmoEMxfzM5hj16/8/O3HsZxTFspfRdpTBzeEOPx71cyrEMuEtnJSag/sxfVhx9HZc9+eHSP6vkiChz/fCSE2ZY4ZtlGnW6UrYjQ9dVxiIp1igXZoktQ9YGBOoL0mIKsVyuWQ3rxXmAqaVbVd73ToleI6ZqYNX9mHaB+n1CmW9paaGkWW3JfLwWZaxZyY+3gb84VmCrTbyU1qXL6kQ2Vo/2F83Xu8foW2js2GbqO5x0gO+faQ/Re8oiQleMJB98pphurPOQO0SBFeMnbaJh7dC2N0y109B8jQxGJ0VAFUX96H+p798OdbwQADnVqfUU/jrzsTBx4zVYcuGgL9ly6FZVXnYq+NR2wbvjbf/JSzUkUOWNhAre8q4agz4V83okKo4ZUDfunbYxnFDktMJTppas7saQjwQmgs0wrt33fNJa2xbCuJ4kpMiHsc3Afy5IRPxa1x/Dk6DxOW9xiHmfoHfYIlfhPnhhDVyKELSs7cMfuMeRYfu6qLuwZn8eTR/XAFlQ5QVxwUg8OUHz2T2RwwYYebrN4eDiFV7E8zHpKBLtEAO/eM4mCJlUiWqxhcUcUP7pqAxZX03D2jeHpdA2X3v4whvW2QWuPcZku4yR9lYyLEsy99BFfnR3BPg0+3kqRp2Nv3q8hkE1xBHvbEe5qMW8YQkaIWlOGSTaO2pnuUwXO+lddta0aChgr5vHCcECPBFwSp/Ge0dB8DTOcML3HpIo9dsDHGj70qpOwuiOOUwaa0ZUMozkSwJZl7djQl8RmlnUSqARdlFWdCZyzoh0TmRKuftEinETAuxNB9LdEMdgRw0m9TWiLBrGW5cViFZed0o+zlrXhRztHDPvefeEas3pvbC6Pi07uRxP315B5AvLKzf0Y5GSd3NeE1bTih2cZMurjLRohJz9HkM9f3qZlgzhy6DDaOzrxvcOTmC7zeLIFLXSbPl6qYBWlp85w8tPlFH4scQ/S
T5V/ymDHCoUQHBxAdM0ShHsIJi28VnT79LxKX/GhodIXemS0tCjZrkcD5odcMY/bUm0hS8LqbEgiJ3eBFxmh51ark/Mc7E+eGsfT42nct38KfXRPpG9v3T2OPWTQvQdm0Emgh1IFtBDsjf1N2DuZw4NDc+bYPfumsKQ1ihiBSbOuKHX4uau7kCCjNRkbBlqwalEzmexDnuKs1cNNPKansPq+k/YPzxXwi73TeIRsFZgdvM4kCRHPqXGCdgzPo3vZIMYtMik9g7ecvBq+uNYbO7iI9uJsMZpgPlYv4dsE1OjVYJxlAbP0PLRhNcKrl8LHyMjSuXSRtDpELpIjd+npIfju3gnnrsc4cVk4Z73qym1mQsVsAurXtzV4gfhaJBuH5sEBa0GCXrFfWMpAZHU3/sB0FmOpIoamMhglA4fmijg8k8fYfIkDzGM0XUS6wNCPuk5A6r3zQ7M5jPC8WTrbT41nTF7RFsV3dpJFPK5HJr86MI0C2w7Tzbl9zwTWk5EC/eecwLVk4kNH5nA31UmF4B5UH+aLGCa4B9n2nN4jN143Ezs7Tv9669JWWMUZ3Hb37VgWovWnxfZ5CXzW9aOfoajuOn28NIu7qrTKip4YNVnRBILrVyHU20nWUZTp4AsBreHy6VVFBkPej+6D9dMHgT2UpgMTsAbaYb3nC9+nS6ZnyhRz+VgOfVC6UhZ9uCyZcf8YMJbXra6gefVGi0/1EKsu47AQWRjqaqvVFjJaMkCK0bThTLoyJseMmc41Bo4/jBGxODg9cWUZt1oOxCYYfTg8YjH2pnTwNL1Dr0jHnKtKRABjSHQd95VUZsLHExJVV79TRH92D+aevg++1Bjm2aeTBs7E57rOwjI7gR21Aq6g7hzRpdKboSYEVi1HaM0yOPRHpSe1TlarthUlaZhOuQx3+6OcsRn4E2EEGMcHT14E671f+q7n6jYUe9V4lEvkWYkuni3Ucd8IRZI6p059w3kyLqhW+QpUnW6yBqgdDU6t6fez0sIxbkzS4WftLxxX
Mn1QWvh97Lh2fmuf+cSksudL8iQqBYQrM4hkRrGI+ZRqBlu71+Hy+Mn4YH4Sny7NUG82M65vgZVsReS0DQjQJXIYfgoL3YUS0fQqo/n6maIiToABnDPuo2GWXrX1hQRZ6RDlPqBCDkw+vGfThSpbKNS1iFQX8yJm88KpZkuV8TwRyywyNQwk2tSjZmDPyvrn2H5j99n7x3aYtG+y9htFx3//1v5z8gslvTAQjqAY7cZsx3q8ZOmF+NSK1+GC6Go8Uyvh1jL1mmL6AF0lfcMqHDLfDHDITOnLhs6kOqS+9+vLPxy/vq9iUw0IA63Nopth3m3SC7oIMew0C754kUCNBmghScFhffqCQJmVGTyPhwxu5tNtzGZtqMBmn9Wo+Y6cobBA/V0j/A8kMVOTpc7/TvReIEn3BILoof95sWujyXXQggjuLuew16Xe9Ud4nEbNpoSRXNLlshgijM+v3x4KqSxGGQ0dfuQIDj2wH+lUGuWQjQKHrXVh3YEy7F3jMepOC7GQlpRQhfCEmhaEpWhdqw6ZS9YSTU2yiWfF0uOgsmyhUWUNU8teTCRlmKqS/6R0DFDVrU9GaOL+0Oqp88+hX7mRE+7R15xyy7hdHw4U2EECquhJdoG6mRrbiLVDcmUzeYzsGsLcjv0I7qORLJRwPlXbeekyNo2ksGk+g1diBpeFpmGtv/4XXnesgu643pesm5W9VTaUYvQxSwqbIIU01gcJjgUrxz4eQK+KWV6rxtfYKjcKmPVep5A+rhf/iCTWm/CQo1TlqlJ1m1s8kozf0wYnN8hzvpQv4Q10l+R3bqcxuiQ3jHl/mH5pl7kvqr7r643NZ6yBTZdybmgcyWeO4jSy80JefxrZ20MmhQiEllzqaw7mS2oxMjhJQ7r57+70tAxGE65vJEV9ZSxpzyHH6TnKSGmW1rxCh8F8ZIXnCFQxWsAKTF1nBie68Hdjn0nlYqiJlzngPzaZ5zcC9IS6BKLak6hIVHVIOuz5EotXsvN66rmc460R0I8Up3AjM6K0
7E2dFHk69BpgjD7n6avhn57Hlp378M5iBedRInWLjz0wILrGXixIirqhdrlrnf53d3hGN7JQL8f2t+TR2lJBcHoOffueQblURpmskOoSI+WpmK8xmH2PdTRAVViqY8fGaCw/C1yx5z8FUNZoZm+h7mPJNMhyMfe5LtMJSY9ANpNRV+sGBvcVD36XxmiHR7rIkZfIa/JJKn3ODa0JLCWgV2YK6GW9OTZJfjWS2ov3wmpa3Ng3I24k6+wb7vQUMkmi/HYdq5bkEfcKeMUPv4fTdz0M1++Hm2M4R3ZoPaUVjZq3ii11nmHZ8cq0EpjgWVF2TIzXmk3qGeOKsXJL6zs5OZ7qUR25bOO4ZoZbhXh6VVt1m3r0mIKT5BWL8OjzaY29Xm44jqXYz0hFfTNfpqEV16o+j/pMdVq01KZO7uv1bV3rsu1CPk8PRvXHzPrOYJksY38EjNr2aL3Vlp4h+Xl+mX0q6HVxRUgam9qVLpd7tfYKgrqUvzVdjeQsPuv12+Qs+2mm+psrWNxTR3NmHqffux0RRhQlVu6cdx58r3g5vPYOVBgTW6duhpdoQm12jrqIPqpAOvNMeK2tZu27lj3a555rjqG7B9iwAZXDR4AVy4Fly1Edn4S9dSstIxmxbBncaByVsXG4iSR8l1wMa+UKVEaOokrxtFavge/yS83EVlQ3+2O+lkPR9Bib+157CexTT0WNhqKanofv4ovZ9jmoaSX01LSp02bfqjNz8FavRuDSS+E/+RS40zOwI1HYp2xif8ZR0+LcTZt4/UW0eVXUhtm++sbjAtN/8snmGiOmMmIVEiLeT5+VLNVjEs00/2ckRctNEQ7SbVrUWjGLR/VRvDpj6Ao77lLp+15/lelMlZVVJTKvfjW8jRtRISurxTJqsQT87343nLe+BVUZMnbIufYNCHzqkwh85tNw/vwKgkNmsMPWK1+JKpnqvPWtCNz4UTjXvAHuypWokFm+a6+B9ZLzUOvqNh98cQcG4Hvn21Hv6YH9xjea68v5olmooH64
Sxljv+UtqA8sNnqtFk/AvvS18JYvh+/tb0etsxNV+pfOtdei1tSMGvsQuPBCOCJEmkwmYPbrrjR1uqvXwvfmN5u2/O98B+p9vfDa2hD/xP+DCOsKXXY5JSlg7IxRYfoMZZxSoBXJ9FmPqRs7Sgrrlbr2WB2LO6rGdYoH6cyL2gtK0YgPRdArUKwpInrnyG5vM290SBUEztkK3/JBBE47Df7NnFHpFc64neAAKToSdYmKRUbax97HyefgdHQg8NLzzLmWzw/fhvVwh0fgI4vt/j44rS1spx2Vu+7iGGz4BgfZfqMu0y+W2fGY2Zol5YrSqCIqv7zXPDt3yGA9FzIfGfDTsD62C7UndqOm13mOHIGlR8Mh9o91+pYsploIsa07yboknP5eMw6t6/efdy7sgX6zrtW0bRJ1bYyS2MNoqk9PT+lAUmrsLPWBYuSeljLaogSHFipIR1+XmfufEmmKefW+XzU6wU67R0fhP+NFCFI8QVCdJUtQue0nqGy/F87atexkGHWem/9vH0buIzeiPjFh9K1HR9jsUxe7Bw6i8Ll/RPXXOzjrNaP3Sj/6MZxVK+GsXG70dXXXblR3PIDINdfCpQqo/HI7xYzRDPurfnnUh/Uh9omTbXW0m99yZUJXXIbq/TtQ27vX6NH60BBFlLpR32aamTXnGf1P/euODBv9Xtmxw9xIjlzzF6jtfBRVgm+HIqj89GcofuFLZjwGzOOAMqkfSsTMfOYzTD2/4q9v9QZCFi7dkMfitqr5GniAAf+Gz34F8dEJ1COcXSpwoz9kXAiWFafuoVhqZl3qHysRhzc5BY9g22SVR12mazwt4JfBIFNdlclw0B0zBiuZMMetIH1AEsyjOEr92P1kAiVB4Htqj/pYE+aOjsLNZBqM0jhkzMh2mywXA13py3QaTneXAbh+aIiMIjuDlC5OgpfNNQwi+yrXSIbKFqiszxyjlIDnOX39BI8TIOOYbCKBOHFUR1ZTk+m3kT4ByeDC2fJ62BtfTgljuYCmSrRWvvNW
bzlF/fXrC0YV1CkaQVa27uavo2Pnk6hqVukM6+Mo5o0zaYGyFuVSTDkgPwH31YoMhTlDbEhfU9SgPb2yQtWgts1HpjkREj+BpIG4RQ5I19OqhmXlZUk1ULGH7DMWXXpJnxymGEPACMxjSQMgQOZ8tmHrQ1yy8ho0WarrTfuyyOyLy+M5sVqLwaQiOAl6qSHEAKbO/hQ48a7aEbBSEeyvAVmTwP7pKxLm7RLTLkU/FIXzsrfCXrrZ3HgxIs1j1loy9PyVBWzqp0tTZ9xOJ9li7Nq0/xDadzzOwdQQo35tCrNC9dziDOla7uoFhqdnQxjLNz4KpS8t6tt2x4VC51A/n8oobFOUHecxj3G0iUa4LXP7y5KDwzULCV70Wz45Z0NqJ0CDqfdNDTkaxY3D5t9GhKYfxkXj+cePq4xbvaXSy4neSj/bqDEdI8gPoYqHIkE0Mwo8jwFMPw2Yno4Yt48A27FjkZ65ZGHLfyQ5nUthrzydx2kT1LGFZJ12/Q+9t1Lc4xEX+px8WHE7wXGDfuP8tgSK6G0uIszAPxAuIRSmX0hLVyeYtYqFvdMhfHd/E35wMIHxObJKry4SAJOqDnoJ5HfWzuKMcJ1EIcMrDBKYbWZfzcZdOR/elfFjnxZTEOvfSkQ5GaqgNVjhZDXAk7TLXuo2osai6EVlDQB/E2CYc/ibw8Jmhnk/5gCbuF8RU+dSuH1+Fp9qCWMTAni/FUIHRZ60YoWszE9AB5rJVIIqlp+YNCkKJPTsXg2fkJzzL7xs2zqKvJhDATJviClq8jibUX8NKzoKHBC7rIdVLDd3pUhPfUZCv3sjNWxpy6PDV8fIfBCTBc5Ylecy692djy1L47VttLxlAklAzCoUAcOsz0+sZedO5qDvIzXmnt23RmIb0UAdyQDdNZ4rzE1kx63IY7bHsn4vZJMMstxQt9W4fwHHtIi/dXdI7131VVxcnK/iZWRonLq1phBWM8EK9A69FZDqkc5+bsdMpY1zn5Ocv7ry0m0RP/1LHgxp5sxJui/q
YXGyjGYOREz0O/pwi+5Y61Yf9aCf51Fh67FAa6iKze1FvJTAdgXoBLOGvmAdb1s8j7f20AARLNVhkZH6/qhg0RMB13WMOlrGvq3kNXdy3miOuPfs3BHWJ3npd1Iy1J4+O7lA0UZ/mB32m90xWxkH3VlXBKm/XhFLOEj2BbCRTFmXqkFvISnS89E+xBj9+GOMonSxYRuvJ64W9blLHWonqLulc4+LwEJ+gWTd/c1ve0WeUKSo6kuDYbJAJIqTFYOtJRoqCr7PpU+rJ3zMHJgvXEYl5aG8kxHWVA3+FhrcRTaCbayx6GAqRZeHIt2jCS9RV5ZpLASm60dthqJ/mEPSp4ObIvAlYxR9BxH+/ixBv4GgMhhsJNNvD6vo0nXG9NUG2gyec5QOh97bH+jixAck4szs99i0h/FJFwP9fgOijJuMpZ5MFuNBnMRj779rGtFyHQXS3PjazIZEzwNSnQbRbqPR7W1tTODvAPJYct500WXbqILFGTMQsUsL7pqCLpIE0iUQIoTEXH+RJhSl3zpsIfsNis736TvuslF4gh1+irqKsuRvtRGPN1av1SnmlSr1plZGM1yrTNSQ3p5G8VAeldkSKpMFsoD+IS2ywyhkE695in3eI6KwD1J+5DVOHyxj60kulvcBs/MWJwxYPmBh40oHrU02WprZXszByFidYbmN9WtDSCZ9iOiv4RBM3Syu06ccikcQmi5i8yy9DQIq9SbP5IWS+uzq0+Y819FfIfj9eFJyqQsDJtMgcSt9rDdp6FnSVXA4S4wwioyjMyFU83QvhsNI/SSIwgO8mjpJr+ZKxVSOAqkfeJj43x6yT9Pie+yMXCkxgWyqF11kHsoSRHoLLLOor/Qt+sKRFM8/ilyWho8+6vuIv16hFpiayDPX1fDyzS4Wd7ENis58zkOCY+tu5SBJQhNak2Xz8y6DJIbPfT5zY1h3zpRlQPWXFCwrYP5QwKfJ1FsojVECSefod2NEtaD37+tjDEgmUw1bpWKpPktWL8r/YGVprdV5fqk3d6yD7oO7Sy98UMGqEWS4iO1p8qoaZb1aQvrOC6hQrZ3LLHnKPF1A+St80zM7IarBTWlepD/ZX5rLI7htBplDEqWTUtUKSl65f7eLVZ9TNC7y6H1sgWWQLWij6+lsgqkauqrL++kIiwhC6mR0iSuaYOU5DGwjTRvoMYUbZ4XdTTXyTJlg3nBm4mj4+L7A8LgBtXxC1o/OoDk3B1d/bYOUqN3fcDMoL5zMRUM409ZafWz9F0wBKcAN6sqczKLYCVco/u9dG5lF2WApcemFBXBQ2anmgHeR5FPc6Bzf/ixJmvptH6ud5zP0sg/wTuuXHjrADEjOHrohWYPiJkBZOVDN55PaMws5VcQVnb12zh/Xr6GlwouTz0jVmO/JJgWaCGQ3TqPC6IOvUg0V9er01aSPCSRaYyuZjCVQlZSdovBJ97zlMQEcDIbyNk/lBr4RJlwaP5SHKA5s4EZtGWgDVxyjPTtOX3j/DUJaZJNDbzeYCGS1iovOct11wxTbdbdYDfB2V+IZpnJqpQ/00SH7qApegZqd9yD7JC+jbUAGQtWQoFbXAtOmrRfs6EOlpR7C1Cb4443YCVaOuqk5Q56Ykl6xdgLKD+hzHPC3M0d4uzNBd8TEaSRSqmG7yMNsTwPJKCPEBYG45LTR71RGqk2k29ScwnyFwTRa6OwgAgdSXy8US3bdIxslC/cUcjkPE0bv3KSeOAsVdY3QJ5txUCbnZKtqifpTo8k07pL3HaI1d1KdkwqqP5+o/2RVJr/kEG8urDCWFkpcvw0ox7E7nUJ/PUc+StSzT31Fx/vL8y7dpNhtQyzwRUJ/+eowYSkbQMa/VS5gf8sOaI6C0kKrWfBe0xHg25Edi+QDCXa16Jg0nHIRfS67bk8av0wcAjFpoNAIfWZluacbeNYM42taK0eYmHE00o9RiYffr46jmSli+v47S+jD2Um+2UqH3ROhpCBytBsx7aCOgbS3Si+qx6rXoR9IIkbVmHDyXBESWzvoMp0Qf
nJWDr6cH05MlLMoXcUWrD8uiAcxQAnb5GDW5GfyqksM+sjZJL6bkqyDrFDETyOEXkRLui2cwnhzGcPtRDHfOohCtIFmOI0Ab4zG09ihZXraM/xel2kWOh6KytwAAAABJRU5ErkJggg==
'@
    [byte[]]$Bytes = [convert]::FromBase64String($B64Logo)
    If (!(Test-Path $LogoImage)) {
        [System.IO.File]::WriteAllBytes($LogoImage,$Bytes)
    }
    #endregion Make Logo

    Function Write-BitLockerKey {
        ## Function writes the bitlocker key information to the table in the WPF UI.
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$True)]
            [String]
            $Source,
            [Parameter(Mandatory=$True)]
            [String]
            $KeyId,
            [Parameter(Mandatory=$True)]
            [String]
            $RecoveryKey
        )
        $window.View1.ItemsSource += [PSCustomObject]@{ Source = "$Source"; KeyId = "$KeyId"; RecoveryKey = "$RecoveryKey"}
        #$window.View1.ScrollIntoView($window.View1.items.Item(($window.View1.ItemsSource).count - 1))
        $window.Dispatcher.Invoke([action]{},"Render")
    }
    
    #Region Common Fuctions for building a WPF UI 
    function Convert-XAMLtoWindow {
        param
        (
            [Parameter(Mandatory=$true)]
            [string]
            $XAML
        )
        
        Add-Type -AssemblyName PresentationFramework
        
        $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
        $result = [Windows.Markup.XAMLReader]::Load($reader)
        $reader.Close()
        $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
        while ($reader.Read())
        {
            $name=$reader.GetAttribute('Name')
            if (!$name) { $name=$reader.GetAttribute('x:Name') }
            if($name)
            {$result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force}
        }
        $reader.Close()
        $result
    }
    
    function Show-WPFWindow {
        param
        (
            [Parameter(Mandatory)]
            [Windows.Window]
            $Window
        )
        
        $result = $null
        $null = $window.Dispatcher.InvokeAsync{
            $result = $window.ShowDialog()
            Set-Variable -Name result -Value $result -Scope 1
        }.Wait()
        $result
    }
    #EndRegion Common Fuctions for building a WPF UI 
    
    #Region XAML for creating the WPF UI - The only variable that goes into this is the logo image.
    $xaml1 = @"
<Window
 xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
 xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
 Title='Find BitLocker Recovery Keys' Width="800"  SizeToContent="Height">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="80" />
                <RowDefinition Height="200" />
                <RowDefinition Height="28" />
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Grid.Column="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="120"/>
                    <ColumnDefinition Width="280"/>
                    <ColumnDefinition Width="100"/>
                    <ColumnDefinition Width="280"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="42" />
                    <RowDefinition Height="42" />
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Grid.Column="0" TextAlignment="Center" Margin="5">BitLocker Key Id:</TextBlock>
                <TextBox Grid.Row="0" Grid.Column="1" Name="KeyId" Margin="5" HorizontalAlignment="left" VerticalContentAlignment="center" Width="250" Height="22"/>
                <Button Grid.Row="0" Grid.Column="2" Name="ConnectGraph" IsDefault="False" MinWidth="80" Height="22" Margin="2" Padding="2" HorizontalAlignment="Right" Background="Yellow" Foreground="Black" FontSize="11">Connect Graph</Button>
                <Image Width="100" Height="84" Grid.Row="0" Grid.Column="3" Grid.RowSpan="2" HorizontalAlignment="right" Margin="0">
                    <Image.Source>
                        <BitmapImage DecodePixelWidth="100" UriSource="$LogoImage" />
                    </Image.Source>
                </Image>
                <Button Grid.Row="1" Grid.Column="1" Name="ButFindKeys" MinWidth="80" Height="22" Margin="180,3,10,2" HorizontalAlignment="Left" FontSize="12" Content="Find Keys" />
            </Grid>
            <ListView Grid.Row="1" Grid.Column="0" Name="View1" SelectionMode="Single">
                <ListView.View>
                    <GridView>
                        <GridViewColumn Width="250" Header="KeyId" DisplayMemberBinding="{Binding KeyId}"/>
                        <GridViewColumn Width="100" Header="Source" DisplayMemberBinding="{Binding Source}"/>
                        <GridViewColumn Width="375" Header="Recovery Key" DisplayMemberBinding="{Binding RecoveryKey}"/>
                    </GridView>
                </ListView.View>
            </ListView>
            <Grid Grid.Row="2" Grid.Column="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="350"/>
                    <ColumnDefinition Width="425"/>
                </Grid.ColumnDefinitions>
                <Button Grid.Column="0" HorizontalAlignment="Left" Name='ClearList' MinWidth="80" Margin="3" Content="Clear List" />
                <Button Grid.Column="1" HorizontalAlignment="Right" Name='CopyRecoveryKey' MinWidth="120" Margin="3" Content="Copy Recovery Key" />
            </Grid>
        </Grid>
    </Window>
"@

    # build the window object to manipulate and interact with in powershell.
    $window = Convert-XAMLtoWindow -XAML $xaml1
    $window.View1.ItemsSource = @()

    #add a Click action to the Find Keys button.
    $window.ButFindKeys.add_Click{
        #change the button to searching....
        $window.ButFindKeys.Content = "Searching..."
        $window.Dispatcher.Invoke([action] {}, "Render")
        #Read the key text from the input box in the dialog
        $KeyToFind = $window.KeyId.Text

        If ($SourcesEnabled.MeId -eq $true){
            $AadKey = Get-MgInformationProtectionBitlockerRecoveryKey -BitlockerRecoveryKeyId "$KeyToFind" -Property Key -ErrorAction SilentlyContinue
            If(-not [string]::IsNullOrEmpty($AadKey.Key)){
                Write-BitLockerKey -Source "Entra ID" -KeyId $KeyToFind -RecoveryKey "$($AadKey.Key)"
            }    
        }

        if ($SourcesEnabled.AD -eq $true){
            $rg=Convert-GuidToHexArray -guid "$KeyToFind"
            $AdKey = Get-ADObject -Filter {objectclass -eq "msFVE-RecoveryInformation" -and msFVE-RecoveryGuid -eq $rg} -Properties msFVE-RecoveryPassword, msFVE-RecoveryGuid | Select-Object @{Name="ComputerName";Expression={(Get-ADComputer -Identity "$(($_.DistinguishedName -split ',')[1..(($_.DistinguishedName -split ',').count -1)] -join ',')").Name}}, @{Name="RecoveryGuid";Expression={[guid]::new($_.'msFVE-RecoveryGuid')}}, msFVE-RecoveryPassword
            If(-not [string]::IsNullOrEmpty($AdKey.'msFVE-RecoveryPassword')){
                Write-BitLockerKey -Source "Active Directory" -KeyId $KeyToFind -RecoveryKey "$($AdKey.'msFVE-RecoveryPassword')"
            }    
        }

        if ($SourcesEnabled.Mbam -eq $true){
            $MbamKey = Get-MBAMKey -KeyId $KeyToFind
            If(-not [string]::IsNullOrEmpty($MbamKey)){
                Write-BitLockerKey -Source "MBAM" -KeyId $KeyToFind -RecoveryKey "$MbamKey"
            }    
        }

        if ($SourcesEnabled.CM -eq $true){
            $Query = "EXEC RecoveryAndHardwareRead.GetRecoveryKey @RecoveryKeyId='$KeyToFind', @Reason='Other'"
            $CMKey = Invoke-SqlDataReader -ServerInstance $SCCMSQLServer -Database $CmDatabase -Query $Query
            If(-not [string]::IsNullOrEmpty($CMKey.RecoveryKey)){
                Write-BitLockerKey -Source "ConfigMgr" -KeyId $KeyToFind -RecoveryKey $CMKey.RecoveryKey
            }
        }
        #set the button back to original text so it shows that its done searching.
        $window.ButFindKeys.Content = "Find Keys"
    }

    #Add click action to button to clear the list of recovered keys.
    $window.ClearList.add_Click{
        $window.View1.ItemsSource = @()
    }

    function Test-GraphConnection {
        $Parameters = @{
            Method = "GET"
            URI = "/v1.0/me"
            OutputType = "HttpResponseMessage"
            ErrorAction = "Stop"
        }
        try {
            $Response = Invoke-GraphRequest @Parameters
            if ($Response) {
                return $true
            }
        } catch {
            return $false
        }    
    }
    function Convert-GuidToHexArray {
        param (
            [string]$guid
        )
    
        # Convert the string GUID to a .NET Guid object
        $guidBytes = [Guid]::Parse($guid).ToByteArray()
    
        # Convert each byte to a hexadecimal string and concatenate it in the required format
        $hexString = ""
        foreach ($byte in $guidBytes) {
            # Convert byte to 2-digit hexadecimal and append
            $hexString += "\" + "{0:X2}" -f $byte
        }
    
        return $hexString
    }
    function Get-MBAMKey {
        [CmdletBinding()]
        param (
            [string]$KeyId
        )
        $soapBody = @"
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <s:Header>
    <wsa:Action>http://tempuri.org/IAdministrationService/GetRecoveryKey</wsa:Action>
    <wsa:To>$mbamUrl</wsa:To>
  </s:Header>
  <s:Body>
    <GetRecoveryKey xmlns="http://tempuri.org/">
      <recoveryKeyId>$KeyId</recoveryKeyId>
      <reasonCode>Other</reasonCode>
    </GetRecoveryKey>
  </s:Body>
</s:Envelope>
"@
        # Perform the SOAP request using Invoke-WebRequest
        try{
            $keyResponse = Invoke-WebRequest -Uri $mbamUrl -Method POST -Body $soapBody -ContentType "application/soap+xml" -UseBasicParsing -UseDefaultCredentials -ErrorAction Stop
            #([xml]$keyResponse.Content).Envelope.Body.GetRecoveryKeyResponse.GetRecoveryKeyResult
            return ([xml]$keyResponse.Content).Envelope.Body.GetRecoveryKeyResponse.GetRecoveryKeyResult.RecoveryKey
        }
        catch{
            return $null
        }
    }

    #region SQL Reader Function - Function i found a long time ago to run sql queries using the built in sql functions.
function Invoke-SqlDataReader {
    
        <#
        .SYNOPSIS
            Runs a select statement query against a SQL Server database.
        
        .DESCRIPTION
            Invoke-SqlDataReader is a PowerShell function that is designed to query
            a SQL Server database using a select statement without the need for the SQL
            PowerShell module or snap-in being installed.
        
        .PARAMETER ServerInstance
            The name of an instance of the SQL Server database engine. For default instances,
            only specify the server name: 'ServerName'. For named instances, use the format
            'ServerName\InstanceName'.
        
        .PARAMETER Database
            The name of the database to query on the specified SQL Server instance.
        
        .PARAMETER Query
            Specifies one Transact-SQL select statement query to be run.
        
        .PARAMETER QueryTimeout
            Specifies how long to wait until the SQL Query times out. default 300 Seconds
        
        .PARAMETER Credential
            SQL Authentication userid and password in the form of a credential object.
        
        .EXAMPLE
            Invoke-SqlDataReader -ServerInstance Server01 -Database Master -Query '
            select name, database_id, compatibility_level, recovery_model_desc from sys.databases'
        
        .EXAMPLE
            'select name, database_id, compatibility_level, recovery_model_desc from sys.databases' |
            Invoke-SqlDataReader -ServerInstance Server01 -Database Master
        
        .EXAMPLE
            'select name, database_id, compatibility_level, recovery_model_desc from sys.databases' |
            Invoke-SqlDataReader -ServerInstance Server01 -Database Master -Credential (Get-Credential)
        
        .INPUTS
            String
        
        .OUTPUTS
            DataRow
        
        .NOTES
            Author:  Mike F Robbins
            Website: http://mikefrobbins.com
            Twitter: @mikefrobbins
        #>
        
        [CmdletBinding()]
        param (        
            [Parameter(Mandatory)]
            [string]$ServerInstance,
        
            [Parameter(Mandatory)]
            [string]$Database,
            
            [Parameter(Mandatory,
                        ValueFromPipeline)]
            [string]$Query,
            
            [Parameter(Mandatory=$false,
                        ValueFromPipeline=$false)]
            [int]$QueryTimeout = 300,

            [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
        )
        BEGIN {
            $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
        
            if (-not($PSBoundParameters.Credential)) {
                $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
            }
            else {
                $connectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=False;"
                $userid= $Credential.UserName -replace '^.*\\|@.*$'
                ($password = $credential.Password).MakeReadOnly()
                $sqlCred = New-Object -TypeName System.Data.SqlClient.SqlCredential($userid, $password)
                $connection.Credential = $sqlCred
            }
            $connection.ConnectionString = $connectionString
            $ErrorActionPreference = 'Stop'
            try {
                $connection.Open()
                Write-Verbose -Message "Connection to the $($connection.Database) database on $($connection.DataSource) has been successfully opened."
            }
            catch {
                Write-Error -Message "An error has occurred. Error details: $($_.Exception.Message)"
            }
            $ErrorActionPreference = 'Continue'
            $command = $connection.CreateCommand()
            $command.CommandTimeout = $QueryTimeout
        }
        PROCESS {
            $command.CommandText = $Query
            $ErrorActionPreference = 'Stop'
            try {
                $result = $command.ExecuteReader()
            }
            catch {
                Write-Error -Message "An error has occured. Error Details: $($_.Exception.Message)"
            }
            $ErrorActionPreference = 'Continue'
            if ($result) {
                $dataTable = New-Object -TypeName System.Data.DataTable
                $dataTable.Load($result)
                $dataTable
            }
        }
        END {
            $connection.Close()
        }
    }
    #endregion SQL Reader

    $window.CopyRecoveryKey.add_Click{
        ($window.View1.SelectedItems).RecoveryKey | Clip
    }

    $window.ConnectGraph.add_Click{
        $Scopes = @(
            "User.Read.All"
            "BitlockerKey.Read.All"
            "DeviceManagementManagedDevices.Read.All"
        )
        Connect-MgGraph -Scopes $Scopes -NoWelcome
        If (Test-GraphConnection){
            $window.ConnectGraph.Background="Green"
            $window.ConnectGraph.Foreground="White"
            $window.ConnectGraph.Content = "Connected"
        }
    }    

    If (Test-GraphConnection){
        $window.ConnectGraph.Background="Green"
        $window.ConnectGraph.Foreground="White"
        $window.ConnectGraph.Content = "Connected"
    }

    $null = Show-WPFWindow -Window $window
}
