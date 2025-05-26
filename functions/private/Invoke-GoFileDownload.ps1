# Function - Download a file from gofile.io
#? Partially based on https://github.com/ltsdw/gofile-downloader
Function Invoke-GoFileDownload {
    Param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('URI')]
        [URI]$URL,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Path')]
        [String]$LiteralPath
    )

    Begin {
		# Function - Convert file size from bytes to an appropriate unit, using binary multipliers like KiB, MiB, GiB etc. (1024 B = 1 KiB, 1024 KiB = 1 MiB, 1024 MiB = 1 GiB ...)
		Function Private:Format-ByteSize {
			Param (
				[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
				[ValidateNotNullOrEmpty()]
				[ValidateRange(0, 79228162514264337593543950335)] # Works up to 64 RiB - 1 B.
				[Alias('Bytes')]
				[Decimal]$Size
			)

			Begin {
				$Prefixes = @('K','M','G','T','P','E','Z','Y','R')
			}

			Process {
				If ($Size -lt 1024) {
					Return "$Size B"
				}
				Else {
					$Counter = -1
					While ($Size -ge 1024) {
						$Counter ++
						$Size /= 1024
					}
					Return "$([Math]::Round($Size, 2)) $($Prefixes[$Counter])iB"
				}
			}
		}		
		
        Try {
            $Null = New-Item -Path (Split-Path $LiteralPath) -ItemType Directory -Force
        }
        Catch {
            Throw "Failed to create a directory '$(Split-Path $LiteralPath)'."
        }
    }

    Process {
        # Extract content ID from URL
        $ContentID = ([String]$URL).Trim().Split('://')[-1].Replace('gofile.io/d/','').Split('/')[0]

        # Prepare UserAgent string and HTTP headers
        #! TODO: Generate UserAgent string dynamically. For now, let PowerShell use it's onw UserAgent string.
        #! $UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0'

        # Obtain user token
        $Headers = @{
            #'Accept-Encoding' = 'gzip, deflate, br';
            'Accept' = '*/*';
            'Connection' = 'keep-alive'
        }
        $WR = Invoke-WebRequest -Method Post -Uri 'https://api.gofile.io/accounts' -Headers $Headers #!-UserAgent $UserAgent
        $Token = (ConvertFrom-Json -InputObject ($WR.Content)).data.token

        # Obtain website token
        $WebsiteToken = Try {
            $WR = Invoke-WebRequest -Uri 'https://gofile.io/dist/js/global.js' -Headers $Headers #!-UserAgent $UserAgent
            $WR.Content.Split("`n").Where{$_ -like 'appdata.wt =*'}.Split('wt = ')[-1].Split('"')[1]
        }
        Catch {
            '4fd6sg89d7s6'
        }

        # Obtain content information - file name, URL, size etc.
        $Headers = @{
          #  'Accept-Encoding' = 'gzip, deflate, br';
            'Accept' = '*/*';
            'Connection' = 'keep-alive';
            'Authorization' = "Bearer $Token"
        }
        $WR = Invoke-WebRequest -Uri "https://api.gofile.io/contents/$($ContentID)?wt=$($WebsiteToken)&cache=true" -Headers $Headers #!-UserAgent $UserAgent

        # Process obtained content information
        $Links = @(
            ForEach ($Child in @((ConvertFrom-Json -InputObject ($WR.Content)).data.children.PSObject.Members.Where{$_.MemberType -eq 'NoteProperty'}.Name)) {
                (ConvertFrom-Json -InputObject ($WR.Content)).data.children.$Child | Select-Object -Property 'name', 'link', 'size'
            }
        )

        # Download file(s)
        $Headers = @{
         #   'Accept-Encoding' = 'gzip, deflate, br';
            'Accept' = '*/*';
            'Referrer' = If ($URL[-1] -eq '/') {$URL} Else {"$URL/"};
            'Origin' = $URL
            'Connection' = 'keep-alive';
            'Sec-Fetch-Dest' = 'empty';
            'Sec-Fetch-Mode' = 'cors';
            'Sec-Fetch-Site' = 'same-site';
            'Pragma' = 'no-cache';
            'Cache-Control' = 'no-cache'
        }
        $Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $Session.Cookies.Add((New-Object System.Net.Cookie('accountToken', $Token, '/', 'gofile.io')))
        $Link = $Links[0]
        Write-Host "Downloading: $($Link.name) ($(Format-ByteSize -Size $Link.size))"
        Invoke-WebRequest -Uri ($Link.link) -OutFile $LiteralPath -WebSession $Session #!-UserAgent $UserAgent
    }
}