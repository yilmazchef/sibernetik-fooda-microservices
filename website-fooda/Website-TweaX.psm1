[CmdletBinding()]
param(
    # The maven project root
    [Parameter( Mandatory = $false, Position = 0, ValueFromPipeline = $true )]
    [System.IO.DirectoryInfo[]]
    $Path = [System.IO.DirectoryInfo]::new($pwd),

    [Parameter( Mandatory = $false, Position = 1 )]
    [string]
    $Keywords
)

$global:Type = $Path.BaseName -split "-" | Select-Object -First 1
$global:Context = $Path.BaseName -split "-" | Select-Object -Last 1
$global:Name = "{0}-{1}" -f $Type, $Context
$global:Path = $Path
$global:DockerUsername = $null -eq $env:DOCKER_USERNAME ? $env:USERNAME : $env:DOCKER_USERNAME

############################## UTILITY FUNCTIONS ##############################

function Write-SuccessSeparator() {
    Write-Host ("#" * ((Get-TerminalSize).Width - 25)) -ForegroundColor Green
}

function Write-FailureSeparator() {
    Write-Host ("#" * ((Get-TerminalSize).Width - 25)) -ForegroundColor Red
}

function Write-WarningSeparator() {
    Write-Host ("#" * ((Get-TerminalSize).Width - 25)) -ForegroundColor Yellow
}

function Write-InfoSeparator() {
    Write-Host ("#" * ((Get-TerminalSize).Width - 25)) -ForegroundColor Gray
}

function Write-NewLine() {
    Write-SuccessSeparator
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Message
Parameter description

.PARAMETER Color
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Write-TerminalMessage() {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $Message, 

        [Parameter( Mandatory = $false, Position = 1, ValueFromPipeline = $true )]
        [string]
        $Color
    )

    if ($null -eq $Color) {
        $Color = Cyan
    }
    
    Write-Host
    Write-Host "##################     $Message     ##################" -ForegroundColor $Color
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Message
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Write-SuccessMessage() {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $Message
    )
    
    Write-TerminalMessage -Message $Message -Color Green
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Message
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Write-ErrorMessage() {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $Message
    )
    
    Write-TerminalMessage -Message $Message -Color Red
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Message
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Write-WarningMessage() {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $Message
    )
    
    Write-TerminalMessage -Message $Message -Color Yellow
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Message
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Write-InfoMessage() {
    
    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $Message
    )
    
    Write-TerminalMessage -Message $Message -Color Cyan
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ImportText
Parameter description

.PARAMETER ExportPath
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function ConvertTo-QRCode() {

    [CmdletBinding()]
    param (

        # The maven project root
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $ImportText,

        [Parameter( Mandatory = $true, Position = 1, ValueFromPipeline = $true )]
        [string]
        $ExportPath
    )

    New-PSOneQRCodeURI -URI $ImportText -Width 15 -OutPath $ExportPath 
}


<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ImportPath
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function ConvertFrom-QRCode() {

    [CmdletBinding()]
    param (
        # The maven project root
        [Parameter( Mandatory = $true, Position = 0, ValueFromPipeline = $true )]
        [string]
        $ImportPath
    )

    $QRCode = New-PSOneQRCode -InPath $ImportPath
    
    return $QRCode.URI
}

function Install-PowershellModuleIfNotExists() {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$Repository = "PSGallery"
    )

    if (!(Get-Module -ListAvailable -Name $ModuleName)) {
        $NextMessage = "Installing $ModuleName ..."
        Write-InfoMessage -Message $NextMessage        
        Install-Module -Name $ModuleName -Force -Scope CurrentUser -Verbose -Repository $Repository
    }

}

############################## BUSINESS FUNCTIONS ##############################

function Invoke-RestApi {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [alias('PrimaryUri')][uri] $BaseUri,
        [alias('Uri')][uri] $RelativeOrAbsoluteUri,
        [System.Collections.IDictionary] $QueryParameter,
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [validateset('GET', 'DELETE', 'POST', 'PATCH')][string] $Method = 'GET',
        [string] $ContentType = "application/json; charset=UTF-8",
        [System.Collections.IDictionary] $Body,
        [switch] $FullUri
    )

    if ($Authorization.Error) {
        Write-Warning "Invoke-RestApi - Authorization error. Skipping."
        return
    }
    $RestSplat = @{
        Headers     = $Headers
        Method      = $Method
        ContentType = $ContentType
        Body        = $Body | ConvertTo-Json -Depth 5
    }
    Remove-EmptyValue -Hashtable $RestSplat

    if ($FullUri) {
        $RestSplat.Uri = $PrimaryUri
    }
    else {
        $RestSplat.Uri = Join-UriQuery -QueryParameter $QueryParameter -BaseUri $BaseUri -RelativeOrAbsoluteUri $RelativeOrAbsoluteUri
    }
    if ($PSCmdlet.ShouldProcess("$($RestSplat.Uri)", "Invoking query with $Method")) {
        try {
            Write-Verbose "Invoke-RestApi - Querying $($RestSplat.Uri) method $Method"
            $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
            if ($Method -in 'GET') {
                if ($OutputQuery) {
                    $OutputQuery
                }

                <#
            if ($OutputQuery.'@odata.nextLink') {
                $RestSplat.Uri = $OutputQuery.'@odata.nextLink'
                $MoreData = Invoke-RestApi @RestSplat -FullUri
                if ($MoreData) {
                    $MoreData
                }
            }
            #>
            }
            elseif ($Method -in 'POST') {
                $OutputQuery
            }
            else {
                return $true
            }
        }
        catch {
            $RestError = $_.ErrorDetails.Message
            if ($RestError) {
                try {
                    $ErrorMessage = ConvertFrom-Json -InputObject $RestError
                    $ErrorMy = -join ('JSON Error:' , $ErrorMessage.error.code, ' ', $ErrorMessage.error.message, ' Additional Error: ', $_.Exception.Message)
                    Write-Warning $ErrorMy
                }
                catch {
                    Write-Warning $_.Exception.Message
                }
            }
            else {
                Write-Warning $_.Exception.Message
            }
            if ($Method -ne 'GET', 'POST') {
                return $false
            }
        }
    }
}

function Connect-Wordpress {
    [cmdletBinding(DefaultParameterSetName = 'Password')]
    param(
        [Parameter(ParameterSetName = 'ClearText')]
        [string] $UserName,
        
        [Parameter(ParameterSetName = 'ClearText')]
        [SecureString] $Password,

        [Parameter(ParameterSetName = 'ClearText')]
        [Parameter(ParameterSetName = 'Password')]
        [alias('Uri')][Uri] $Url,
        [Parameter(ParameterSetName = 'Password')]
        [pscredential] $Credential
    )
    if ($Username -and $Password) {
        $UserNameApi = $UserName
        $PasswordApi = $Password
    }
    elseif ($Credential) {
        $UserNameApi = $Credential.UserName
        $PasswordApi = $Credential.GetNetworkCredential().Password
    }
    $Authorization = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$UserNameApi`:$PasswordApi")))
    $Auth = @{
        Header = @{
            Authorization = -join ("Basic ", $Authorization)
        }
        Url    = $Url
    }
    $Auth
}


function Get-WordPressCategory {
    [cmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(ParameterSetName = 'List', Mandatory)]
        [Parameter(ParameterSetName = 'Id', Mandatory)]
        [System.Collections.IDictionary] $Authorization,

        [Parameter(ParameterSetName = 'Id')][int[]] $Id,
        [Parameter(ParameterSetName = 'List')][int] $Page,
        [Parameter(ParameterSetName = 'List')][int] $RecordsPerPage,
        [Parameter(ParameterSetName = 'List')][string] $Search,
        [Parameter(ParameterSetName = 'List')][string] $Exclude,
        [Parameter(ParameterSetName = 'List')][string] $Include,
        [Parameter(ParameterSetName = 'List')][string] $Slug,
        [Parameter(ParameterSetName = 'List')][string] $Parent,
        [Parameter(ParameterSetName = 'List')][string] $Post,
        [Parameter(ParameterSetName = 'List')][ValidateSet('view', 'embed', 'edit')][string] $Context,
        [Parameter(ParameterSetName = 'List')][ValidateSet('asc', 'desc')][string] $Order,
        [Parameter(ParameterSetName = 'List')][ValidateSet('id', 'include', 'name', 'slug', 'include_slugs', 'term_group', 'description', 'count')][string] $OrderBy,
        [switch] $HideUnused
    )
    if ($Id) {
        foreach ($I in $Id) {
            Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/categories/$I" -Headers $Authorization.Header -QueryParameter @{}
        }
    }
    else {
        $QueryParameters = [ordered] @{
            context = $Context
            search  = $Search
            include = $Include
            exclude = $Exclude
            order   = $Order
            orderby = $OrderBy
            slug    = $Slug
            tags    = $Tags
            parent  = $Parent
            post    = $Post
        }
        if ($HideUnused) {
            $QueryParameters['hide_empty'] = $HideUnused.IsPresent
        }
        if ($Page) {
            $QueryParameters['page'] = $Page
        }
        if ($RecordsPerPage) {
            $QueryParameters['per_page'] = $RecordsPerPage
        }
        Remove-EmptyValue -Hashtable $QueryParameters
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/categories' -QueryParameter $QueryParameters -Headers $Authorization.Header
    }
}

function Get-WordPressPage {
    [cmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(ParameterSetName = 'List', Mandatory)]
        [Parameter(ParameterSetName = 'Id', Mandatory)]
        [System.Collections.IDictionary] $Authorization,

        [Parameter(ParameterSetName = 'Id')][int] $Id,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('edit', 'view')][string[]] $Context,
        [Parameter(ParameterSetName = 'List')][int] $Include,
        [Parameter(ParameterSetName = 'List')][int] $Exclude,
        [Parameter(ParameterSetName = 'List')][int] $Page,
        [Parameter(ParameterSetName = 'List')][int] $RecordsPerPage,
        [Parameter(ParameterSetName = 'List')][string] $Search,
        [Parameter(ParameterSetName = 'List')][string] $Author,
        [Parameter(ParameterSetName = 'List')][string] $ExcludeAuthor,
        [ValidateSet('publish', 'future', 'draft', 'pending', 'private')][Parameter(ParameterSetName = 'List')][string[]] $Status,
        [Parameter(ParameterSetName = 'List')][string] $Slug,
        [Parameter(ParameterSetName = 'List')][int[]] $Tags,
        [Parameter(ParameterSetName = 'List')][int[]] $ExcludeTags,
        [Parameter(ParameterSetName = 'List')][int[]] $Categories,
        [Parameter(ParameterSetName = 'List')][int[]] $ExcludeCategories,
        [Parameter(ParameterSetName = 'List')][ValidateSet('asc', 'desc')][string] $Order,
        [Parameter(ParameterSetName = 'List')][ValidateSet('author', 'date', 'id', 'include', 'modified', 'parent', 'relevance', 'slug', 'include_slugs', 'title')][string] $OrderBy
    )

    if ($Id) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/pages/$id" -Headers $Authorization.Header -QueryParameter @{}
    }
    else {
        $QueryParameters = [ordered] @{
            search         = $Search
            author         = $Author
            author_exclude = $ExcludeAuthor
            status         = $Status
            order          = $Order
            orderby        = $OrderBy
            slug           = $Slug
            context        = $Context
        }
        if ($Tags) {
            $QueryParameters['tags'] = $Tags
        }
        if ($Categories) {
            $QueryParameters['categories'] = $Categories
        }
        if ($ExcludeTags) {
            $QueryParameters['tags_exclude'] = $ExludeTags
        }
        if ($ExcludeCategories) {
            $QueryParameters['categories_exclude'] = $ExcludeCategories
        }
        if ($Include) {
            $QueryParameters['include'] = $Include
        }
        if ($Exclude) {
            $QueryParameters['exclude'] = $Exclude
        }
        if ($Page) {
            $QueryParameters['page'] = $Page
        }
        if ($RecordsPerPage) {
            $QueryParameters['per_page'] = $RecordsPerPage
        }
        Remove-EmptyValue -Hashtable $QueryParameters
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/pages' -QueryParameter $QueryParameters -Headers $Authorization.Header
    }
}

function Get-WordPressPost {
    [cmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(ParameterSetName = 'List', Mandatory)]
        [Parameter(ParameterSetName = 'Id', Mandatory)]
        [System.Collections.IDictionary] $Authorization,

        [Parameter(ParameterSetName = 'Id')][int] $Id,

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('edit', 'view')][string[]] $Context,

        [Parameter(ParameterSetName = 'List')][int] $Include,
        [Parameter(ParameterSetName = 'List')][int] $Exclude,
        [Parameter(ParameterSetName = 'List')][int] $Page,
        [Parameter(ParameterSetName = 'List')][int] $RecordsPerPage,
        [Parameter(ParameterSetName = 'List')][string] $Search,
        [Parameter(ParameterSetName = 'List')][string] $Author,
        [Parameter(ParameterSetName = 'List')][string] $ExcludeAuthor,
        [ValidateSet('publish', 'future', 'draft', 'pending', 'private')][Parameter(ParameterSetName = 'List')][string[]] $Status,
        [Parameter(ParameterSetName = 'List')][string] $Slug,
        [Parameter(ParameterSetName = 'List')][int[]] $Tags,
        [Parameter(ParameterSetName = 'List')][int[]] $ExcludeTags,
        [Parameter(ParameterSetName = 'List')][int[]] $Categories,
        [Parameter(ParameterSetName = 'List')][int[]] $ExcludeCategories,
        [Parameter(ParameterSetName = 'List')][ValidateSet('asc', 'desc')][string] $Order,
        [Parameter(ParameterSetName = 'List')][ValidateSet('author', 'date', 'id', 'include', 'modified', 'parent', 'relevance', 'slug', 'include_slugs', 'title')][string] $OrderBy
    )

    if ($Id) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/posts/$id" -Headers $Authorization.Header -QueryParameter @{}
    }
    else {
        $QueryParameters = [ordered] @{
            search         = $Search
            author         = $Author
            author_exclude = $ExcludeAuthor
            status         = $Status
            order          = $Order
            orderby        = $OrderBy
            slug           = $Slug
            context        = $Context
        }
        if ($Tags) {
            $QueryParameters['tags'] = $Tags
        }
        if ($Categories) {
            $QueryParameters['categories'] = $Categories
        }
        if ($ExcludeTags) {
            $QueryParameters['tags_exclude'] = $ExludeTags
        }
        if ($ExcludeCategories) {
            $QueryParameters['categories_exclude'] = $ExcludeCategories
        }
        if ($Include) {
            $QueryParameters['include'] = $Include
        }
        if ($Exclude) {
            $QueryParameters['exclude'] = $Exclude
        }
        if ($Page) {
            $QueryParameters['page'] = $Page
        }
        if ($RecordsPerPage) {
            $QueryParameters['per_page'] = $RecordsPerPage
        }
        Remove-EmptyValue -Hashtable $QueryParameters
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/posts' -QueryParameter $QueryParameters -Headers $Authorization.Header
    }
}

function Get-WordPressTag {
    [cmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(ParameterSetName = 'List', Mandatory)]
        [Parameter(ParameterSetName = 'Id', Mandatory)]
        [System.Collections.IDictionary] $Authorization,

        [Parameter(ParameterSetName = 'Id')][int[]] $Id,
        [Parameter(ParameterSetName = 'List')][int] $Page,
        [Parameter(ParameterSetName = 'List')][int] $RecordsPerPage,
        [Parameter(ParameterSetName = 'List')][string] $Search,
        [Parameter(ParameterSetName = 'List')][string] $Exclude,
        [Parameter(ParameterSetName = 'List')][string] $Include,
        [Parameter(ParameterSetName = 'List')][string] $Slug,
        [Parameter(ParameterSetName = 'List')][string] $Parent,
        [Parameter(ParameterSetName = 'List')][string] $Post,
        [Parameter(ParameterSetName = 'List')][ValidateSet('view', 'embed', 'edit')][string] $Context,
        [Parameter(ParameterSetName = 'List')][ValidateSet('asc', 'desc')][string] $Order,
        [Parameter(ParameterSetName = 'List')][ValidateSet('id', 'include', 'name', 'slug', 'include_slugs', 'term_group', 'description', 'count')][string] $OrderBy,
        [Parameter(ParameterSetName = 'List')][switch] $HideUnused
    )
    if ($Id) {
        foreach ($I in $Id) {
            Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/tags/$I" -Headers $Authorization.Header -QueryParameter @{}
        }
    }
    else {
        $QueryParameters = [ordered] @{
            context = $Context
            search  = $Search
            include = $Include
            exclude = $Exclude
            order   = $Order
            orderby = $OrderBy
            slug    = $Slug
            tags    = $Tags
            parent  = $Parent
            post    = $Post
        }
        if ($HideUnused) {
            $QueryParameters['hide_empty'] = $HideUnused.IsPresent
        }
        if ($Page) {
            $QueryParameters['page'] = $Page
        }
        if ($RecordsPerPage) {
            $QueryParameters['per_page'] = $RecordsPerPage
        }
        Remove-EmptyValue -Hashtable $QueryParameters
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/tags' -QueryParameter $QueryParameters -Headers $Authorization.Header
    }
}

function Get-WordPressSetting {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization
    )
    $QueryParameters = [ordered] @{

    }
    Remove-EmptyValue -Hashtable $QueryParameters
    Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/settings' -QueryParameter $QueryParameters -Headers $Authorization.Header
}

function Get-WordPressTaxonomy {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][string] $Taxonomy
    )
    $QueryParameters = [ordered] @{

    }
    Remove-EmptyValue -Hashtable $QueryParameters
    Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/taxonomies/$Taxonomy" -QueryParameter $QueryParameters -Headers $Authorization.Header
}

function New-WordPressPage {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $Date,
        [string] $Slug,
        [ValidateSet('publish', 'future', 'draft', 'pending', 'private')][string] $Status,
        [string] $Title,
        [int] $Parent,
        [SecureString] $Password,
        [string] $Content,
        [int] $Author,
        [string] $Excerpt,
        [int] $FeaturedMedia,
        [ValidateSet('open', 'closed')][string] $CommentStatus,
        [ValidateSet('open', 'closed')][string] $PingStatus,
        [string] $Meta,
        [string] $Template,
        [int] $MenuOrder
    )
    $QueryParameters = [ordered] @{
        title          = $Title
        date           = $Date
        slug           = $Slug
        status         = $Status
        password       = $Password
        content        = $Content
        excerpt        = $Excerpt
        comment_status = $CommentStatus
        ping_status    = $PingStatus
        meta           = $Meta
        template       = $Template
    }
    if ($Parent) {
        $QueryParameters['parent'] = $Parent
    }
    if ($FeaturedMedia) {
        $QueryParameters['featured_media'] = $FeaturedMedia
    }
    if ($Author) {
        $QueryParameters['author'] = $Author
    }
    if ($MenuOrder) {
        $QueryParameters['menu_order'] = $MenuOrder
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/pages' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "New-WordPressPage - parameters not provided. Skipping."
    }
}

function New-WordPressPost {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $Date,
        [string] $Slug,
        [ValidateSet('publish', 'future', 'draft', 'pending', 'private')][string] $Status,
        [string] $Title,
        [SecureString] $Password,
        [string] $Content,
        [int] $Author,
        [string] $Excerpt,
        [int] $FeaturedMedia,
        [ValidateSet('open', 'closed')][string] $CommentStatus,
        [ValidateSet('open', 'closed')][string] $PingStatus,
        [ValidateSet('standard', 'aside', 'chat', 'gallery', 'link', 'image', 'quote', 'status', 'video', 'audio')][string] $Format,
        [string] $Meta,
        [nullable[bool]] $Sticky,
        [int[]] $Tags,
        [int[]] $Categories

    )
    $QueryParameters = [ordered] @{
        title          = $Title
        date           = $Date
        slug           = $Slug
        status         = $Status
        password       = $Password
        content        = $Content
        excerpt        = $Excerpt
        comment_status = $CommentStatus
        ping_status    = $PingStatus
        format         = $Format
        meta           = $Meta
    }

    if ($Tags) {
        $QueryParameters['tags'] = $Tags
    }
    if ($Categories) {
        $QueryParameters['categories'] = $Categories
    }
    if ($FeaturedMedia) {
        $QueryParameters['featured_media'] = $FeaturedMedia
    }
    if ($Author) {
        $QueryParameters['author'] = $Author
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/posts' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "New-WordPressPost - parameters not provided. Skipping."
    }
}

function New-WordPressTag {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $Name,
        [string] $Slug,
        [string] $Description,
        [int] $Parent
    )
    $QueryParameters = [ordered] @{
        name        = $Name
        slug        = $Slug
        description = $Description
        parent      = $Parent
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/tags' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "New-WordPressTag - parameters not provided. Skipping."
    }
}

function New-WordPressUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $Username,
        [string] $Password,
        [string] $Email,
        [string] $Url,
        [string] $Description,
        [string] $FirstName,
        [string] $LastName,
        [string] $Nickname,
        [string] $Slug,
        [string] $Roles,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        username    = $Username
        password    = $Password
        email       = $Email
        url         = $Url
        description = $Description
        first_name  = $FirstName
        last_name   = $LastName
        nickname    = $Nickname
        slug        = $Slug
        roles       = $Roles
        meta        = $Meta
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/users' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "New-WordPressUser - parameters not provided. Skipping."
    }
}

function Remove-EmptyValue {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Hashtable
    )
    foreach ($Key in $Hashtable.Keys) {
        if ($Hashtable[$Key] -eq $null) {
            $Hashtable.Remove($Key)
        }
    }
}

function Remove-WordPressComment {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id
    )
    if ($PSCmdlet.ShouldProcess($Id, "Remove-WordPressComment")) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/comments/$Id" -Headers $Authorization.Header -Method DELETE
    }
}

function Remove-WordPressMedia {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id
    )
    if ($PSCmdlet.ShouldProcess($Id, "Remove-WordPressMedia")) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/media/$Id" -Headers $Authorization.Header -Method DELETE
    }
}

function Remove-WordPressPage {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [switch] $Force
    )
    $QueryParameters = [ordered] @{}
    if ($Force) {
        $QueryParameters['force'] = $Force.IsPresent
    }
    Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/pages/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method DELETE
}

function Remove-WordPressPost {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [switch] $Force
    )
    $QueryParameters = [ordered] @{}
    if ($Force) {
        $QueryParameters['force'] = $Force.IsPresent
    }
    Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/posts/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method DELETE
}

function Remove-WordPressTag {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id
    )
    if ($PSCmdlet.ShouldProcess($Id, "Remove-WordPressTag")) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/tags/$Id" -Headers $Authorization.Header -Method DELETE
    }
}

function Remove-WordPressUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id
    )
    if ($PSCmdlet.ShouldProcess($Id, "Remove-WordPressUser")) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/users/$Id" -Headers $Authorization.Header -Method DELETE
    }
}

function Set-WordPressComment {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Author,
        [string] $AuthorEmail,
        [string] $AuthorUrl,
        [string] $AuthorIp,
        [string] $Date,
        [string] $DateGmt,
        [string] $Content,
        [string] $Karma,
        [string] $Approved,
        [string] $Agent,
        [string] $Type,
        [string] $Parent,
        [string] $UserId
    )
    $QueryParameters = [ordered] @{
        author       = $Author
        author_email = $AuthorEmail
        author_url   = $AuthorUrl
        author_ip    = $AuthorIp
        date         = $Date
        date_gmt     = $DateGmt
        content      = $Content
        karma        = $Karma
        approved     = $Approved
        agent        = $Agent
        type         = $Type
        parent       = $Parent
        user_id      = $UserId
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/comments/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressComment - parameters not provided. Skipping."
    }
}

function Set-WordPressPage {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Date,
        [string] $Slug,
        [ValidateSet('publish', 'future', 'draft', 'pending', 'private')][string] $Status,
        [string] $Title,
        [int] $Parent,
        [SecureString] $Password,
        [string] $Content,
        [int] $Author,
        [string] $Excerpt,
        [int] $FeaturedMedia,
        [ValidateSet('open', 'closed')][string] $CommentStatus,
        [ValidateSet('open', 'closed')][string] $PingStatus,
        [string] $Meta,
        [string] $Template,
        [int] $MenuOrder
    )
    $QueryParameters = [ordered] @{
        title          = $Title
        date           = $Date
        slug           = $Slug
        status         = $Status
        password       = $Password
        content        = $Content
        excerpt        = $Excerpt
        comment_status = $CommentStatus
        ping_status    = $PingStatus
        meta           = $Meta
        template       = $Template
    }
    if ($Parent) {
        $QueryParameters['parent'] = $Parent
    }
    if ($FeaturedMedia) {
        $QueryParameters['featured_media'] = $FeaturedMedia
    }
    if ($Author) {
        $QueryParameters['author'] = $Author
    }
    if ($MenuOrder) {
        $QueryParameters['menu_order'] = $MenuOrder
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/pages/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressPage - parameters not provided. Skipping."
    }
}

function Set-WordPressPost {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Date,
        [string] $Slug,
        [ValidateSet('publish', 'future', 'draft', 'pending', 'private')][string] $Status,
        [string] $Title,
        [SecureString] $Password,
        [string] $Content,
        [int] $Author,
        [string] $Excerpt,
        [int] $FeaturedMedia,
        [ValidateSet('open', 'closed')][string] $CommentStatus,
        [ValidateSet('open', 'closed')][string] $PingStatus,
        [ValidateSet('standard', 'aside', 'chat', 'gallery', 'link', 'image', 'quote', 'status', 'video', 'audio')][string] $Format,
        [string] $Meta,
        [nullable[bool]] $Sticky,
        [int[]] $Tags,
        [int[]] $Categories

    )
    $QueryParameters = [ordered] @{
        title          = $Title
        date           = $Date
        slug           = $Slug
        status         = $Status
        password       = $Password
        content        = $Content
        excerpt        = $Excerpt
        comment_status = $CommentStatus
        ping_status    = $PingStatus
        format         = $Format
        meta           = $Meta
    }

    if ($Tags) {
        $QueryParameters['tags'] = $Tags
    }
    if ($Categories) {
        $QueryParameters['categories'] = $Categories
    }
    if ($FeaturedMedia) {
        $QueryParameters['featured_media'] = $FeaturedMedia
    }
    if ($Author) {
        $QueryParameters['author'] = $Author
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/posts/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressPost - parameters not provided. Skipping."
    }
}

function Set-WordPressSetting {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $Title,
        [string] $Description,
        [string] $Url,
        [string] $Email,
        [string] $TimeZone,
        [string] $DateFormat,
        [string] $TimeFormat,
        [string] $StartOfWeek,
        [string] $Language,
        [int] $PostsPerPage,
        [int] $DefaultCategory,
        [int] $DefaultPostFormat,
        [nullable[bool]] $UseSmiles,
        [ValidateSet('open', 'closed')][string] $DefaultPingStatus,
        [ValidateSet('open', 'closed')][string] $DefaultCommentStatus
    )
    $QueryParameters = [ordered] @{
        title                  = $Title
        description            = $Description
        url                    = $Url
        email                  = $Email
        timezone               = $TimeZone
        date_format            = $DateFormat
        time_format            = $TimeFormat
        start_of_week          = $StartOfWeek
        language               = $Language
        default_comment_status = $DefaultPingStatus
        default_ping_status    = $DefaultCommentStatus
    }
    if ($null -ne $UseSmiles) {
        $QueryParameters['use_smiles'] = $UseSmiles
    }
    if ($DefaultCategory) {
        $QueryParameters['posts_per_page'] = $PostsPerPage
    }
    if ($PostsPerPage) {
        $QueryParameters['default_category'] = $DefaultCategory
    }
    if ($DefaultPostFormat) {
        $QueryParameters['default_post_format'] = $DefaultPostFormat
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/settings' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressSetting - parameters not provided. Skipping."
    }
}

function Set-WordPressTag {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Name,
        [string] $Slug,
        [string] $Description,
        [int] $Parent,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        name        = $Name
        slug        = $Slug
        description = $Description
        parent      = $Parent
        meta        = $Meta
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/tags/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressTag - parameters not provided. Skipping."
    }
}

function Set-WordPressTaxonomy {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Name,
        [string] $Slug,
        [string] $Description,
        [int] $Parent,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        name        = $Name
        slug        = $Slug
        description = $Description
        parent      = $Parent
        meta        = $Meta
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/taxonomies/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressTaxonomy - parameters not provided. Skipping."
    }
}

function Set-WordPressTerm {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Name,
        [string] $Slug,
        [string] $Description,
        [int] $Parent,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        name        = $Name
        slug        = $Slug
        description = $Description
        parent      = $Parent
        meta        = $Meta
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/terms/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressTerm - parameters not provided. Skipping."
    }
}

function Set-WordPressUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Username,
        [string] $Name,
        [string] $FirstName,
        [string] $LastName,
        [string] $Email,
        [string] $Url,
        [string] $Description,
        [string] $Locale,
        [string] $Nickname,
        [string] $Slug,
        [string] $RegisteredDate,
        [string] $Roles,
        [SecureString] $Password,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        username    = $Username
        name        = $Name
        first_name  = $FirstName
        last_name   = $LastName
        email       = $Email
        url         = $Url
        description = $Description
        locale      = $Locale
        nickname    = $Nickname
        slug        = $Slug
        roles       = $Roles
        password    = $Password
        meta        = $Meta
    }
    if ($RegisteredDate) {
        $QueryParameters['registered_date'] = $RegisteredDate
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/users/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressUser - parameters not provided. Skipping."
    }
}

function Set-WordPressUserMeta {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Key,
        [string] $Value
    )
    $QueryParameters = [ordered] @{
        key   = $Key
        value = $Value
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/users/$Id/meta" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressUserMeta - parameters not provided. Skipping."
    }
}

function Set-WordPressWidget {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][string] $WidgetId,
        [Parameter(Mandatory)][string] $WidgetType,
        [Parameter(Mandatory)][string] $WidgetName,
        [Parameter(Mandatory)][string] $WidgetDescription,
        [Parameter(Mandatory)][string] $WidgetClass,
        [Parameter(Mandatory)][string] $WidgetSettings
    )
    $QueryParameters = [ordered] @{
        id          = $WidgetId
        type        = $WidgetType
        name        = $WidgetName
        description = $WidgetDescription
        class       = $WidgetClass
        settings    = $WidgetSettings
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/widgets' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressWidget - parameters not provided. Skipping."
    }
}

function Set-WordPressWidgetPosition {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][string] $Sidebar,
        [Parameter(Mandatory)][string] $WidgetId,
        [Parameter(Mandatory)][int] $Position
    )
    $QueryParameters = [ordered] @{
        sidebar  = $Sidebar
        widgetId = $WidgetId
        position = $Position
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/widget-positions' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressWidgetPosition - parameters not provided. Skipping."
    }
}

function Set-WordPressWidgetVisibility {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][string] $WidgetId,
        [Parameter(Mandatory)][string] $Visibility
    )
    $QueryParameters = [ordered] @{
        widgetId   = $WidgetId
        visibility = $Visibility
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri 'wp-json/wp/v2/widget-visibility' -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressWidgetVisibility - parameters not provided. Skipping."
    }
}

function Set-WordPressComment {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Author,
        [string] $AuthorEmail,
        [string] $AuthorUrl,
        [string] $AuthorIp,
        [string] $Date,
        [string] $DateGmt,
        [string] $Content,
        [string] $Karma,
        [string] $Parent,
        [string] $Post,
        [string] $Status,
        [string] $Type,
        [string] $AuthorUserAgent,
        [string] $AuthorName,
        [string] $AuthorAvatarUrls,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        author             = $Author
        author_email       = $AuthorEmail
        author_url         = $AuthorUrl
        author_ip          = $AuthorIp
        date               = $Date
        date_gmt           = $DateGmt
        content            = $Content
        karma              = $Karma
        parent             = $Parent
        post               = $Post
        status             = $Status
        type               = $Type
        author_user_agent  = $AuthorUserAgent
        author_name        = $AuthorName
        author_avatar_urls = $AuthorAvatarUrls
        meta               = $Meta
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/comments/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressComment - parameters not provided. Skipping."
    }
}

function Set-WordPressCommentMeta {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Key,
        [string] $Value
    )
    $QueryParameters = [ordered] @{
        key   = $Key
        value = $Value
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/comments/$Id/meta" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressCommentMeta - parameters not provided. Skipping."
    }
}

function Set-WordPressMedia {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Author,
        [string] $Date,
        [string] $DateGmt,
        [string] $Guid,
        [string] $Modified,
        [string] $ModifiedGmt,
        [string] $Slug,
        [string] $Status,
        [string] $Type,
        [string] $Link,
        [string] $Title,
        [string] $CommentStatus,
        [string] $PingStatus,
        [string] $Template,
        [string] $Description,
        [string] $Caption,
        [string] $AltText,
        [string] $MediaType,
        [string] $MimeType,
        [string] $Post,
        [string] $SourceUrl,
        [string] $Meta
    )
    $QueryParameters = [ordered] @{
        author         = $Author
        date           = $Date
        date_gmt       = $DateGmt
        guid           = $Guid
        modified       = $Modified
        modified_gmt   = $ModifiedGmt
        slug           = $Slug
        status         = $Status
        type           = $Type
        link           = $Link
        title          = $Title
        comment_status = $CommentStatus
        ping_status    = $PingStatus
        template       = $Template
        description    = $Description
        caption        = $Caption
        alt_text       = $AltText
        media_type     = $MediaType
        mime_type      = $MimeType
        post           = $Post
        source_url     = $SourceUrl
        meta           = $Meta
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/media/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressMedia - parameters not provided. Skipping."
    }
}

function Set-WordPressMediaMeta {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][int] $Id,
        [string] $Key,
        [string] $Value
    )
    $QueryParameters = [ordered] @{
        key   = $Key
        value = $Value
    }
    Remove-EmptyValue -Hashtable $QueryParameters
    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wp/v2/media/$Id/meta" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "Set-WordPressMediaMeta - parameters not provided. Skipping."
    }
}

function New-WooCommerceProduct() {

    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [Parameter(Mandatory)][string] $Name,
        [string] $Type = "simple",
        [string] $Status = "publish",
        [string] $Featured = $false,
        [string] $CatalogVisibility = "visible",
        [string] $Description = "",
        [string] $ShortDescription = "",
        [string] $Sku = "",
        [string] $Price = 0.00,
        [string] $RegularPrice = 0.00
    )

    $QueryParameters = [ordered] @{
        name               = $Name
        type               = $Type
        status             = $Status
        featured           = $Featured
        catalog_visibility = $CatalogVisibility
        description        = $Description
        short_description  = $ShortDescription
        sku                = $Sku
        price              = $Price
        regular_price      = $RegularPrice        
    }

    Remove-EmptyValue -Hashtable $QueryParameters

    if ($QueryParameters.Keys.Count -gt 0) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wc/v3/products" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method POST
    }
    else {
        Write-Warning "New-WooCommerceProduct - parameters not provided. Skipping."
    }
    
}

function Get-WooCommerceProduct {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [int] $Id,
        [string] $Context,
        [string] $Page,
        [string] $PerPage,
        [string] $Search,
        [string] $After,
        [string] $Before,
        [string] $Exclude,
        [string] $Include,
        [string] $Offset,
        [string] $Order,
        [string] $OrderBy,
        [string] $Slug,
        [string] $Status,
        [string] $Type,
        [string] $Category,
        [string] $Tag,
        [string] $ShippingClass,
        [string] $Attribute,
        [string] $AttributeTerm,
        [string] $Sku,
        [string] $Featured,
        [string] $Visibility,
        [string] $CatalogVisibility,
        [string] $OnSale,
        [string] $MinPrice,
        [string] $MaxPrice,
        [string] $StockStatus,
        [string] $TagId,
        [string] $CategoryId,
        [string] $ShippingClassId,
        [string] $AttributeId,
        [string] $AttributeTermId,
        [string] $TaxClass,
        [string] $InStock,
        [string] $ReviewsAllowed,
        [string] $AverageRating,
        [string] $TotalSales,
        [string] $Backorders,
        [string] $LowStockAmount,
        [string] $SoldIndividually,
        [string] $Weight,
        [string] $Dimensions,
        [string] $ShippingRequired,
        [string] $ShippingTaxable,
        [string] $Description,
        [string] $ShortDescription,
        [string] $Price,
        [string] $RegularPrice,
        [string] $SalePrice,
        [string] $DateOnSaleFrom,
        [string] $DateOnSaleFromGmt,
        [string] $DateOnSaleTo,
        [string] $DateOnSaleToGmt,
        [string] $PriceHtml,
        [string] $Purchasable
    )

    $QueryParameters = [ordered] @{
        context               = $Context
        page                  = $Page
        per_page              = $PerPage
        search                = $Search
        after                 = $After
        before                = $Before
        exclude               = $Exclude
        include               = $Include
        offset                = $Offset
        order                 = $Order
        orderby               = $OrderBy
        slug                  = $Slug
        status                = $Status
        type                  = $Type
        category              = $Category
        tag                   = $Tag
        shipping_class        = $ShippingClass
        attribute             = $Attribute
        attribute_term        = $AttributeTerm
        sku                   = $Sku
        featured              = $Featured
        visibility            = $Visibility
        catalog_visibility    = $CatalogVisibility
        on_sale               = $OnSale
        min_price             = $MinPrice
        max_price             = $MaxPrice
        stock_status          = $StockStatus
        tag_id                = $TagId
        category_id           = $CategoryId
        shipping_class_id     = $ShippingClassId
        attribute_id          = $AttributeId
        attribute_term_id     = $AttributeTermId
        tax_class             = $TaxClass
        in_stock              = $InStock
        reviews_allowed       = $ReviewsAllowed
        average_rating        = $AverageRating
        total_sales           = $TotalSales
        backorders            = $Backorders
        low_stock_amount      = $LowStockAmount
        sold_individually     = $SoldIndividually
        weight                = $Weight
        dimensions            = $Dimensions
        shipping_required     = $ShippingRequired
        shipping_taxable      = $ShippingTaxable
        description           = $Description
        short_description     = $ShortDescription
        price                 = $Price
        regular_price         = $RegularPrice
        sale_price            = $SalePrice
        date_on_sale_from     = $DateOnSaleFrom
        date_on_sale_from_gmt = $DateOnSaleFromGmt
        date_on_sale_to       = $DateOnSaleTo
        date_on_sale_to_gmt   = $DateOnSaleToGmt
        price_html            = $PriceHtml
        purchasable           = $Purchasable
    }
    Remove-EmptyValue -Hashtable $QueryParameters

    if ($Id) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wc/v3/products/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method GET
    }
    else {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wc/v3/products" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method GET
    }

}

function Get-WooCommerceProductAttribute {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [int] $Id,
        [string] $Context,
        [string] $Page,
        [string] $PerPage,
        [string] $Search,
        [string] $After,
        [string] $Before,
        [string] $Exclude,
        [string] $Include,
        [string] $Offset,
        [string] $Order,
        [string] $OrderBy,
        [string] $Slug,
        [string] $Status,
        [string] $Type,
        [string] $Category,
        [string] $Tag,
        [string] $ShippingClass,
        [string] $Attribute,
        [string] $AttributeTerm,
        [string] $Sku,
        [string] $Featured,
        [string] $Visibility,
        [string] $CatalogVisibility,
        [string] $OnSale,
        [string] $MinPrice,
        [string] $MaxPrice,
        [string] $StockStatus,
        [string] $TagId,
        [string] $CategoryId,
        [string] $ShippingClassId,
        [string] $AttributeId,
        [string] $AttributeTermId,
        [string] $TaxClass,
        [string] $InStock,
        [string] $ReviewsAllowed,
        [string] $AverageRating,
        [string] $TotalSales,
        [string] $Backorders,
        [string] $LowStockAmount,
        [string] $SoldIndividually,
        [string] $Weight,
        [string] $Dimensions,
        [string] $ShippingRequired,
        [string] $ShippingTaxable,
        [string] $Description,
        [string] $ShortDescription,
        [string] $Price,
        [string] $RegularPrice,
        [string] $SalePrice,
        [string] $DateOnSaleFrom,
        [string] $DateOnSaleFromGmt,
        [string] $DateOnSaleTo,
        [string] $DateOnSaleToGmt,
        [string] $PriceHtml,
        [string] $Purchasable
    )

    $QueryParameters = [ordered] @{
        context               = $Context
        page                  = $Page
        per_page              = $PerPage
        search                = $Search
        after                 = $After
        before                = $Before
        exclude               = $Exclude
        include               = $Include
        offset                = $Offset
        order                 = $Order
        orderby               = $OrderBy
        slug                  = $Slug
        status                = $Status
        type                  = $Type
        category              = $Category
        tag                   = $Tag
        shipping_class        = $ShippingClass
        attribute             = $Attribute
        attribute_term        = $AttributeTerm
        sku                   = $Sku
        featured              = $Featured
        visibility            = $Visibility
        catalog_visibility    = $CatalogVisibility
        on_sale               = $OnSale
        min_price             = $MinPrice
        max_price             = $MaxPrice
        stock_status          = $StockStatus
        tag_id                = $TagId
        category_id           = $CategoryId
        shipping_class_id     = $ShippingClassId
        attribute_id          = $AttributeId
        attribute_term_id     = $AttributeTermId
        tax_class             = $TaxClass
        in_stock              = $InStock
        reviews_allowed       = $ReviewsAllowed
        average_rating        = $AverageRating
        total_sales           = $TotalSales
        backorders            = $Backorders
        low_stock_amount      = $LowStockAmount
        sold_individually     = $SoldIndividually
        weight                = $Weight
        dimensions            = $Dimensions
        shipping_required     = $ShippingRequired
        shipping_taxable      = $ShippingTaxable
        description           = $Description
        short_description     = $ShortDescription
        price                 = $Price
        regular_price         = $RegularPrice
        sale_price            = $SalePrice
        date_on_sale_from     = $DateOnSaleFrom
        date_on_sale_from_gmt = $DateOnSaleFromGmt
        date_on_sale_to       = $DateOnSaleTo
        date_on_sale_to_gmt   = $DateOnSaleToGmt
        price_html            = $PriceHtml
        purchasable           = $Purchasable
    }
    Remove-EmptyValue -Hashtable $QueryParameters

    if ($Id) {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wc/v3/products/attributes/$Id" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method GET
    }
    else {
        Invoke-RestApi -PrimaryUri $Authorization.Url -Uri "wp-json/wc/v3/products/attributes" -QueryParameter $QueryParameters -Headers $Authorization.Header -Method GET
    }

}

function Get-Dockerfile() {

    $Dockerfile = @'

FROM wordpress:apache

ENV WORDPRESS_DB_HOST=db-{0}
ENV WORDPRESS_DB_USER={0}
ENV WORDPRESS_DB_PASSWORD={0}
ENV WORDPRESS_DB_NAME={0}

## COPY ./wp-content /var/www/html/wp-content
## COPY ./wp-config.php /var/www/html/wp-config.php
## COPY ./wp-config-docker.php /var/www/html/wp-config-docker.php
## COPY ./wp-config-local.php /var/www/html/wp-config-local.php

EXPOSE 80
EXPOSE 443

'@ -f $global:Context

    Write-Output $Dockerfile

}


function Get-DockerComposeYamlLocal() {

    $UIFQN = "docker.io" + "/" + $global:DockerUsername + "/" + "ui-" + $global:Context + ":latest"
    $DBFQN = "docker.io" + "/" + $global:DockerUsername + "/" + "db-" + $global:Context + ":latest"
    $DBAFQN = "docker.io" + "/" + $global:DockerUsername + "/" + "dba-" + $global:Context + ":latest"

    $YamlResponse = @'
version: '3.7'

services:

    ########################################################################################################################################################

    ### {0} Wordpress Docker composition settings for ui-{0} and db-{0} ###

    ########################################################################################################################################################
    
    ui-{0}:
        image: {1}
        build: 
            context: .
            dockerfile: Dockerfile
        restart: unless-stopped
        container_name: ui-{0}
        ports:
            - "8888:80"
        depends_on:
            - db-{0}
        environment:
            WORDPRESS_DB_HOST: db-{0}
            WORDPRESS_DB_USER: {0}
            WORDPRESS_DB_PASSWORD: {0}
            WORDPRESS_DB_NAME: {0}
        volumes:
            - disk-ui:/var/www/html
        networks:
            - {0}-net
            - cloud-net


    db-{0}:
        image: {2}
        container_name: db-{0}
        restart: unless-stopped
        ports:
            - "3333:3306"
        environment:
            MYSQL_DATABASE: {0}
            MYSQL_USER: {0}
            MYSQL_PASSWORD: {0}
            MYSQL_ROOT_PASSWORD: {0}
            MYSQL_ALLOW_EMPTY_PASSWORD: "no"
            MYSQL_RANDOM_ROOT_PASSWORD: "no"
            MYSQL_ONETIME_PASSWORD: "no"
            MYSQL_INITDB_SKIP_TZINFO: "no"
        volumes:
            - disk-db:/var/lib/mysql/
        networks:
            - {0}-net
            - cloud-net
    
    dba-{0}:
        image: {3}
        container_name: dba-{0}
        restart: unless-stopped
        depends_on:
            db-{0}:
                condition: service_started
        environment:
            ADMINER_DB: {0}
            ADMINER_DRIVER: mysql
            ADMINER_PASSWORD: {0}
            ADMINER_SERVER: db-{0}
            ADMINER_USERNAME: {0}
            ADMINER_AUTOLOGIN: 1
            ADMINER_NAME: DB Admin for {0}
        ports:
            - "9999:8080"
        networks:
            - {0}-net
            - cloud-net


###############################################################################################

### Networks to be created to facilitate communication between containers ###

###############################################################################################

networks:
    cloud-net:
        driver: bridge
    {0}-net:

###############################################################################################

### Volumes to be created to facilitate to share resources between containers ###

###############################################################################################

volumes:
    disk-ui:
    disk-db:

'@

    $YamlResponse = $YamlResponse -f $global:Context, $UIFQN, $DBFQN, $DBAFQN
    
    Write-Output $YamlResponse

}

function Get-ReadMe() {


    $Markdown = @'

# Website-TweaX

## What we DO provide 

## web publish setup
    -- %50 of the payment is received
    -- hosting 
    -- domain name
    -- email account
    -- under construction template is uploaded to the web server..
 
### auto deploy wp + mysql on docker
    -- customize initialization: title, email, username, password..
    -- default language is chosen English
    -- username and password is for developer: environment variables from 'WORDPRESS_DEV_USER', 'WORDPRESS_DEV_PASSWORD'
    -- as soon as the deployment is complete, all templates found will be sent to the customer via an email and the developer.

( progress: 2 weeks )

### customization (wp theme, woo-commerce, plugins etc.)
    -- customer chooses a template
    -- developer installs and customizes the template
    -- all design content will be packed into a figma project with .fig extention

( progress: 3 weeks )

### customer input (photo gallery, product info, about us..)
    -- will be retrieved from the customer !!!
    -- for products: email!! excel sheet, csv, google sheets
    -- for photos: email!!! facebook, instagram, flickr, google drive, onedrive ..
    -- for company info (about us + contact ..): email!!! ms word, email, whatsapp..

( progress: 4 weeks, if scraping is required +1 week and extra cost. )

### after all data is received from the customer,
    -- upload data via wp REST API or wp-cli 
        --- about us -> create new page request
        --- contact -> create new page request
        --- products excel -> create new product from csv/excel
        --- photo/video gallery -> create new gallery item request

( progress: 5 weeks )

### Validate the website quality and ask feedback from the customer.
    -- send an email asking the customer to check his/her website.
    -- make a list of update/fix suggestions.
    -- if the feedback contains only minor changes no charge.
    -- if the feedback contains major changes provide a new price offer based on the changes and working-hours.

( progress: 6 weeks )

### Job is done. 
    -- the remaining %50 of the payment is received.

### Helpdesk
    -- 1 year free of charge minor changes in the website (09:00 - 18:00 support via email)
    -- 1 year domain name + 1 year hosting + 1 year email service.

## What we do NOT provide 

### Helpdesk
    -- 24/7 support via phone calls. (only one day a week between monday and friday)
    -- Free of charge major changes in the website
    -- Payment of domain/hosting renewals (must be paid by the customer every year)


The WordPress rich content management system can utilize plugins, widgets, and themes.

[Overview](https://hub.docker.com/_/wordpress)[Tags](https://hub.docker.com/_/wordpress/tags)

# Quick reference

-   **Maintained by**:  
    [the Docker Community](https://github.com/docker-library/wordpress)
    
-   **Where to get help**:  
    [the Docker Community Forums](https://forums.docker.com/), [the Docker Community Slack](https://dockr.ly/slack), or [Stack Overflow](https://stackoverflow.com/search?tab=newest&q=docker)
    

# What is WordPress?

WordPress is a free and open source blogging tool and a content management system (CMS) based on PHP and MySQL, which runs on a web hosting service. Features include a plugin architecture and a template system. WordPress is used by more than 22.0% of the top 10 million websites as of August 2013. WordPress is the most popular blogging system in use on the Web, at more than 60 million websites. The most popular languages used are English, Spanish and Bahasa Indonesia.

> [wikipedia.org/wiki/WordPress](https://en.wikipedia.org/wiki/WordPress)

![logo](wordpress%20-%20Official%20Image%20%20Docker%20Hub/medialogo.png)

# How to use this image

```console
$ docker run --name some-wordpress --network some-network -d wordpress
```

The following environment variables are also honored for configuring your WordPress instance (by [a custom `wp-config.php` implementation](https://github.com/docker-library/wordpress/blob/master/wp-config-docker.php)):

-   `-e WORDPRESS_DB_HOST=...`
-   `-e WORDPRESS_DB_USER=...`
-   `-e WORDPRESS_DB_PASSWORD=...`
-   `-e WORDPRESS_DB_NAME=...`
-   `-e WORDPRESS_TABLE_PREFIX=...`
-   `-e WORDPRESS_AUTH_KEY=...`, `-e WORDPRESS_SECURE_AUTH_KEY=...`, `-e WORDPRESS_LOGGED_IN_KEY=...`, `-e WORDPRESS_NONCE_KEY=...`, `-e WORDPRESS_AUTH_SALT=...`, `-e WORDPRESS_SECURE_AUTH_SALT=...`, `-e WORDPRESS_LOGGED_IN_SALT=...`, `-e WORDPRESS_NONCE_SALT=...` (default to unique random SHA1s, but only if other environment variable configuration is provided)
-   `-e WORDPRESS_DEBUG=1` (defaults to disabled, non-empty value will enable `WP_DEBUG` in `wp-config.php`)
-   `-e WORDPRESS_CONFIG_EXTRA=...` (defaults to nothing, non-empty value will be embedded verbatim inside `wp-config.php` -- especially useful for applying extra configuration values this image does not provide by default such as `WP_ALLOW_MULTISITE`; see [docker-library/wordpress#142](https://github.com/docker-library/wordpress/pull/142) for more details)

The `WORDPRESS_DB_NAME` needs to already exist on the given MySQL server; it will not be created by the `wordpress` container.

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

```console
$ docker run --name "some-wordpress" -p "8888:80" -d wordpress
```

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser.

When running WordPress with TLS behind a reverse proxy such as NGINX which is responsible for doing TLS termination, be sure to set `X-Forwarded-Proto` appropriately (see ["Using a Reverse Proxy" in "Administration Over SSL" in upstream's documentation](https://wordpress.org/support/article/administration-over-ssl/#using-a-reverse-proxy)). No additional environment variables or configuration should be necessary (this image automatically adds the noted `HTTP_X_FORWARDED_PROTO` code to `wp-config.php` if _any_ of the above-noted environment variables are specified).

If your database requires SSL, [WordPress ticket #28625](https://core.trac.wordpress.org/ticket/28625) has the relevant details regarding support for that with WordPress upstream. As a workaround, [the "Secure DB Connection" plugin](https://wordpress.org/plugins/secure-db-connection/) can be extracted into the WordPress directory and the appropriate values described in the configuration of that plugin added in `wp-config.php`.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run --name some-wordpress -e WORDPRESS_DB_PASSWORD_FILE=/run/secrets/mysql-root ... -d wordpress:tag
```

Currently, this is supported for `WORDPRESS_DB_HOST`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_NAME`, `WORDPRESS_AUTH_KEY`, `WORDPRESS_SECURE_AUTH_KEY`, `WORDPRESS_LOGGED_IN_KEY`, `WORDPRESS_NONCE_KEY`, `WORDPRESS_AUTH_SALT`, `WORDPRESS_SECURE_AUTH_SALT`, `WORDPRESS_LOGGED_IN_SALT`, `WORDPRESS_NONCE_SALT`, `WORDPRESS_TABLE_PREFIX`, and `WORDPRESS_DEBUG`.

## ... via [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or [`docker-compose`](https://github.com/docker/compose)

Example `stack.yml` for `wordpress`:

```yaml
version: '3.7'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - "8888:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
```

[![Try in PWD](wordpress%20-%20Official%20Image%20%20Docker%20Hub/mediabutton.png)](http://play-with-docker.com?stack=https://raw.githubusercontent.com/docker-library/docs/456252a739783650c79bd1f6a7a19101fbecfc65/wordpress/stack.yml)

Run `docker stack deploy -c stack.yml wordpress` (or `docker-compose -f stack.yml up`), wait for it to initialize completely, and visit `http://swarm-ip:8080`, `http://localhost:8080`, or `http://host-ip:8080` (as appropriate).

## Adding additional libraries / extensions

This image does not provide any additional PHP extensions or other libraries, even if they are required by popular plugins (e.g. [it cannot send e-mails](https://github.com/docker-library/wordpress/issues/30)). There are an infinite number of possible plugins, and they potentially require any extension PHP supports. Including every PHP extension that exists would dramatically increase the image size.

If you need additional PHP extensions, you'll need to create your own image `FROM` this one. The [documentation of the `php` image](https://github.com/docker-library/docs/blob/master/php/README.md#how-to-install-more-php-extensions) explains how to compile additional extensions. Additionally, [an older `Dockerfile` for `wordpress`](https://github.com/docker-library/wordpress/blob/618490d4bdff6c5774b84b717979bfe3d6ba8ad1/apache/Dockerfile#L5-L9) has a simplified example of doing this and [a newer version of that same `Dockerfile`](https://github.com/docker-library/wordpress/blob/5bbbfa8909232af10ea3fea8b80302a6041a2d04/latest/php7.4/apache/Dockerfile#L18-L62) has a much more thorough example.

## Include pre-installed themes / plugins

Mount the volume containing your themes or plugins to the proper directory; and then apply them through the "wp-admin" UI. Ensure read/write/execute permissions are in place for the user:

-   Themes go in a subdirectory in `/var/www/html/wp-content/themes/`
-   Plugins go in a subdirectory in `/var/www/html/wp-content/plugins/`

If you wish to provide additional content in an image for deploying in multiple installations, place it in the same directories under `/usr/src/wordpress/` instead (which gets copied to `/var/www/html/` on the container's initial startup).

## Static image / updates-via-redeploy

The default configuration for this image matches the official WordPress defaults in which automatic updates are enabled (so the initial install comes from the image, but after that it becomes self-managing within the `/var/www/html/` data volume).

If you wish to have a more static deployment (similar to other containerized applications) and deploy new containers to update WordPress + themes/plugins, then you'll want to use something like the following (and run the resulting image read-only):

```dockerfile
FROM wordpress:apache
WORKDIR /usr/src/wordpress
RUN set -eux; \
find /etc/apache2 -name '*.conf' -type f -exec sed -ri -e "s!/var/www/html!$PWD!g" -e "s!Directory /var/www/!Directory $PWD!g" '{}' +; \
cp -s wp-config-docker.php wp-config.php
COPY custom-theme/ ./wp-content/themes/custom-theme/
COPY custom-plugin/ ./wp-content/plugins/custom-plugin/
```

For FPM-based images, remove the `find` instruction and adjust the `SCRIPT_FILENAME` paths in your reverse proxy from `/var/www/html` to `/usr/src/wordpress`.

Run the result read-only, providing writeable storage for `/tmp`, `/run`, and (optionally) `wp-content/uploads`:

On Linux:

```console
$ docker run ... \
--read-only \
--tmpfs /tmp \
--tmpfs /run \
--mount type=...,src=...,dst=/usr/src/wordpress/wp-content/uploads \
... \
--env WORDPRESS_DB_HOST=... \
--env WORDPRESS_AUTH_KEY=... \
--env ... \
custom-wordpress:tag
```

On Powershell:

```console
$ docker run ... `
--read-only `
--tmpfs /tmp `
--tmpfs /run `
--mount type=...,src=...,dst=/usr/src/wordpress/wp-content/uploads `
... `
--env WORDPRESS_DB_HOST=... `
--env WORDPRESS_AUTH_KEY=... `
--env ... `
custom-wordpress:tag
```


**Note:** be sure to rebuild and redeploy regularly to ensure you get all the latest WordPress security updates.

## Running as an arbitrary user

See [the "Running as an arbitrary user" section of the `php` image documentation](https://github.com/docker-library/docs/blob/master/php/README.md#running-as-an-arbitrary-user).

When running WP-CLI via the `cli` variants of this image, it is important to note that they're based on Alpine, and have a default `USER` of Alpine's `www-data`, whose UID is `82` (compared to the Debian-based WordPress variants whose default effective UID is `33`), so when running `wordpress:cli` against an existing Debian-based WordPress install, something like `--user 33:33` is likely going to be necessary (possibly also something like `-e HOME=/tmp` depending on the `wp` command invoked and whether it tries to use `~/.wp-cli`). See [docker-library/wordpress#256](https://github.com/docker-library/wordpress/issues/256) for more discussion around this.

## Configuring PHP directives

See [the "Configuration" section of the `php` image documentation](https://github.com/docker-library/docs/blob/master/php/README.md#configuration).

For example, to adjust common `php.ini` flags like `upload_max_filesize`, you could create a `custom.ini` with the desired parameters and place it in the `$PHP_INI_DIR/conf.d/` directory:

```dockerfile
FROM wordpress:tag
COPY custom.ini $PHP_INI_DIR/conf.d/
```

# Image Variants

The `wordpress` images come in many flavors, each designed for a specific use case.

## `wordpress:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `wordpress:<version>-fpm`

This variant contains PHP-FPM, which is a FastCGI implementation for PHP. See [the PHP-FPM website](https://php-fpm.org/) for more information about PHP-FPM.

In order to use this image variant, some kind of reverse proxy (such as NGINX, Apache, or other tool which speaks the FastCGI protocol) will be required.

Some potentially helpful resources:

-   [PHP-FPM.org](https://php-fpm.org/)
-   [simplified example by @md5](https://gist.github.com/md5/d9206eacb5a0ff5d6be0)
-   [very detailed article by Pascal Landau](https://www.pascallandau.com/blog/php-php-fpm-and-nginx-on-docker-in-windows-10/)
-   [Stack Overflow discussion](https://stackoverflow.com/q/29905953/433558)
-   [Apache httpd Wiki example](https://wiki.apache.org/httpd/PHPFPMWordpress)

**WARNING:** the FastCGI protocol is inherently trusting, and thus _extremely_ insecure to expose outside of a private container network -- unless you know _exactly_ what you are doing (and are willing to accept the extreme risk), do not use Docker's `--publish` (`-p`) flag with this image variant.

## `wordpress:cli`

This image variant does not contain WordPress itself, but instead contains [WP-CLI](https://wp-cli.org).

The simplest way to use it with an existing WordPress container would be something similar to the following:

```console
$ docker run -it --rm \
--volumes-from some-wordpress \
--network container:some-wordpress \
-e WORDPRESS_DB_USER=... \
-e WORDPRESS_DB_PASSWORD=... \
# [and other used environment variables]
wordpress:cli user list
```

Generally speaking, for WP-CLI to interact with a WordPress install, it needs access to the on-disk files of the WordPress install, and access to the database (and the easiest way to accomplish that such that `wp-config.php` does not require changes is to simply join the networking context of the existing and presumably working WordPress container, but there are many other ways to accomplish that which will be left as an exercise for the reader).

**NOTE:** Since March 2021, WordPress images use a customized `wp-config.php` that pulls the values directly from the environment variables defined above (see `wp-config-docker.php` in [docker-library/wordpress#572](https://github.com/docker-library/wordpress/pull/572) and [docker-library/wordpress#577](https://github.com/docker-library/wordpress/pull/577)). As a result of reading environment variables directly, the cli container also needs the same set of environment variables to properly evaluate `wp-config.php`.

# License

View [license information](https://wordpress.org/about/license/) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `wordpress/` directory](https://github.com/docker-library/repo-info/tree/master/repos/wordpress).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

    
'@

    Write-Output $Markdown

}

function Invoke-ThemeFromMonsterTemplate() {

    
}

function Get-WPConfigFile() {

    $WPConfigFile = @'

<?php

/**

 * The base configuration for WordPress

 *

 * The wp-config.php creation script uses this file during the

 * installation. You don't have to use the web site, you can

 * copy this file to "wp-config.php" and fill in the values.

 *

 * This file contains the following configurations:

 *

 * * MySQL settings

 * * Secret keys

 * * Database table prefix

 * * ABSPATH

 *

 * @link https://wordpress.org/support/article/editing-wp-config-php/

 *

 * @package WordPress

 */

// ** MySQL settings - You can get this info from your web host ** //

/** The name of the database for WordPress */

define('DB_NAME', {0});
define('DB_USER', {0});
define('DB_PASSWORD', {0});
define('DB_HOST', db-{0});
define('DB_CHARSET', utf8mb4);
define('DB_PORT', 3306);
define('DB_PREFIX', getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_');

/** Website settings */

define('WP_HOME', getenv('WORDPRESS_HOME') ?: 'http://localhost');
define('WP_SITEURL', getenv('WORDPRESS_SITEURL') ?: 'http://localhost');
define('WP_CONTENT_DIR', getenv('WORDPRESS_CONTENT_DIR') ?: '/var/www/html/wp-content');
define('WP_CONTENT_URL', getenv('WORDPRESS_CONTENT_URL') ?: 'http://localhost/wp-content');
define('WP_DEFAULT_THEME', getenv('WORDPRESS_DEFAULT_THEME') ?: 'twentyseventeen');
define('WP_DEBUG', getenv('WORDPRESS_DEBUG') ?: false);
define('WP_DEBUG_LOG', getenv('WORDPRESS_DEBUG_LOG') ?: false);
define('WP_DEBUG_DISPLAY', getenv('WORDPRESS_DEBUG_DISPLAY') ?: false);


/** Custom settings */

define('AUTOMATIC_UPDATER_DISABLED', getenv('WORDPRESS_AUTOMATIC_UPDATER_DISABLED') ?: true);
define('DISABLE_WP_CRON', getenv('WORDPRESS_DISABLE_WP_CRON') ?: true);
define('DISALLOW_FILE_EDIT', getenv('WORDPRESS_DISALLOW_FILE_EDIT') ?: true);
define('DISALLOW_FILE_MODS', getenv('WORDPRESS_DISALLOW_FILE_MODS') ?: true);
define('FORCE_SSL_ADMIN', getenv('WORDPRESS_FORCE_SSL_ADMIN') ?: false);
define('WP_ALLOW_MULTISITE', getenv('WORDPRESS_ALLOW_MULTISITE') ?: false);
define('WP_AUTO_UPDATE_CORE', getenv('WORDPRESS_AUTO_UPDATE_CORE') ?: false);
define('WP_CACHE', getenv('WORDPRESS_CACHE') ?: false);
define('WP_CRON_LOCK_TIMEOUT', getenv('WORDPRESS_CRON_LOCK_TIMEOUT') ?: 60);
define('WP_POST_REVISIONS', getenv('WORDPRESS_POST_REVISIONS') ?: 3);

/** Absolute path to the WordPress directory. */

if ( !defined('ABSPATH') )

define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */

require_once(ABSPATH . 'wp-settings.php');


'@ -f $global:Context

    Write-Output $WPConfigFile


}


function Update-ImageTags() {

    $DBImageName = "db-" + $global:Context + ":latest"
    $DBAImageName = "dba-" + $global:Context + ":latest"
    $UIImageName = "ui-" + $global:Context + ":latest"

    $DBFQN = "docker.io" + "/" + $global:DockerUsername + "/" + $DBImageName
    $DBAFQN = "docker.io" + "/" + $global:DockerUsername + "/" + $DBAImageName
    $UIFQN = "docker.io" + "/" + $global:DockerUsername + "/" + $UIImageName

    docker pull mysql:5.7
    docker tag mysql:5.7 $DBFQN

    docker pull adminer:latest
    docker tag adminer:latest $DBAFQN

    docker build -t $UIImageName -f .\Dockerfile .
    docker tag $UIImageName $UIFQN

}

function Push-ImageTags() {

    $DBImageName = "db-" + $global:Context + ":latest"
    $DBAImageName = "dba-" + $global:Context + ":latest"
    $UIImageName = "ui-" + $global:Context + ":latest"

    $DBFQN = "docker.io" + "/" + $global:DockerUsername + "/" + $DBImageName
    $DBAFQN = "docker.io" + "/" + $global:DockerUsername + "/" + $DBAImageName
    $UIFQN = "docker.io" + "/" + $global:DockerUsername + "/" + $UIImageName

    docker tag $DBImageName $DBFQN
    docker push $DBFQN

    docker tag $DBAImageName $DBAFQN
    docker push $DBAFQN

    docker tag $UIImageName $UIFQN
    docker push $UIFQN

}

function Save-DockerComposeYaml() {

    $Yaml = Get-DockerComposeYamlLocal
    $Yaml | Out-File -FilePath ".\docker-compose.yml" -Encoding UTF8 -Force

    docker pull pmsipilot/docker-compose-viz
    docker tag pmsipilot/docker-compose-viz yilmazchef/sibernetik-netmap:latest
    
    docker run --rm -it --name dcv -v ${pwd}:/input yilmazchef/sibernetik-netmap render -m image docker-compose.yml --force
}

function Save-Dockerfile() {

    $Dockerfile = Get-Dockerfile
    $Dockerfile | Out-File -FilePath ".\Dockerfile" -Encoding UTF8 -Force

}

function Save-WPConfig() {

    $WPConfigFile = Get-WPConfigFile
    $WPConfigFile | Out-File -FilePath ".\wp-config.php" -Encoding UTF8 -Force
    $WPConfigFile | Out-File -FilePath ".\wp-config-docker.php" -Encoding UTF8 -Force
    $WPConfigFile | Out-File -FilePath ".\wp-config-local.php" -Encoding UTF8 -Force

}

function Save-Readme() {

    $Readme = Get-Readme
    $Readme | Out-File -FilePath ".\README.md" -Encoding UTF8 -Force

}

function Save-All() {

    Save-DockerComposeYaml
    Save-Dockerfile
    Save-WPConfig
    Save-Readme
}

function Start-All() {
    docker-compose up -d
}

function Push-PSGallery() {

    Publish-Module @{
        Name         = $global:Context
        NuGetApiKey  = $global:PSGalleryApiKey
        Path         = $global:Path
        Repository   = $global:PSGalleryRepo
        ReleaseNotes = "Initial release"
        Tags         = "WordPress", "Docker", "DockerCompose", "DockerComposeYaml", "Dockerfile", "WPConfig", "WPConfigLocal", "WPConfigDocker", "Readme"
    }
}

function Push-GitHub() {

    git add .
    git commit -m "Initial commit"
    git push -u origin master
}

function Push-All() {

    Push-PSGallery
    Push-GitHub
}

function Invoke-WordPressLocal() {

    $PathSeparator = [System.IO.Path]::DirectorySeparatorChar
    $WordPressPath = $global:Path.FullName + $PathSeparator + "wordpress"

    if (Test-Path $WordPressPath) {
        Write-ErrorMessage "WordPress already exists at $WordPressPath"
        return
    }

    $WordPressZip = "https://wordpress.org/latest.zip"
    $WordPressZipFile = "latest.zip"
    $WordPressZipPath = $WordPressPath + $PathSeparator + $WordPressZipFile

    Invoke-WebRequest -Uri $WordPressZip -OutFile $WordPressZipPath
    Expand-Archive -Path $WordPressZipPath -DestinationPath $global:Path.FullName
    # Remove-Item -Path $WordPressZipPath
}

function Install-WordPressLocal() {

    $PathSeparator = [System.IO.Path]::DirectorySeparatorChar
    $WordPressPath = $global:Path.FullName + $PathSeparator + "wordpress"

    if (Test-Path $WordPressPath) {
        Write-ErrorMessage "WordPress already exists at $WordPressPath"
        return
    }


    $WordPressPath = $global:Path.FullName + $PathSeparator + "wordpress"

    New-Item -ItemType Directory -Path $WordPressPath + $PathSeparator + "wp-content" + $PathSeparator + "plugins" -Force
    New-Item -ItemType Directory -Path $WordPressPath + $PathSeparator + "wp-content" + $PathSeparator + "themes" -Force
    New-Item -ItemType Directory -Path $WordPressPath + $PathSeparator + "wp-content" + $PathSeparator + "uploads" -Force

    $WordPressConfigPath = $WordPressPath + $PathSeparator + "wp-config.php"
    Get-WPConfigFile | Out-File -FilePath $WordPressConfigPath -Encoding UTF8 -Force

}


function Invoke-ThemeForestThemePreviews() {

    $KeywordUriString = $Keywords -replace " ", "%20" 

    $QueryString = "https://themeforest.net/category/wordpress?compatible_with=WooCommerce&tags=" + $KeywordUriString + "#content"
    $WebResponse = Invoke-WebRequest -Uri $QueryString -Method Get

    if ($WebResponse.StatusCode -ne 200) {
        Write-Error "Error: $Response.StatusCode"
        return
    }

    $Result = @()

    $WebResponse.Links `
    | Where-Object { $_.href -match "https://themeforest.net/item/" -and $_.href -match "full_screen_preview" } `
    | Select-Object href, innerHTML, outerHTML `
    | ForEach-Object {
        $Result += @{
            "Path" = $_.href
            "Data" = $_.outerHTML
        }
    }

    Write-Output $Result

}

function Invoke-TemplateMonsterThemePreviews() {

    $KeywordUriString = $Keywords -replace " ", "+"

    $QueryString = "https://www.templatemonster.com/woocommerce-themes/?text=" + $KeywordUriString

    $WebResponse = Invoke-WebRequest -Uri $QueryString -Method Get

    if ($WebResponse.StatusCode -ne 200) {
        Write-Error "Error: $Response.StatusCode"
        return
    }

    $Result = @()

    $WebResponse.Links `
    | Where-Object { $_.Href -match "https://www.templatemonsterpreview.com/" } `
    | Select-Object href, innerHTML, outerHTML `
    | ForEach-Object {
        $Result += @{
            "Path" = $_.href
            "Data" = $_.outerHTML
        }
    }

    Write-Output $Result

}

function Invoke-WordpressOrgThemePreviews() {

    $KeywordUriString = $Keywords -replace " ", "%20"

    $QueryString = "https://wordpress.org/themes/search/" + $KeywordUriString

    $WebResponse = Invoke-WebRequest -Uri $QueryString -Method Get

    if ($WebResponse.StatusCode -ne 200) {
        Write-Error "Error: $Response.StatusCode"
        return
    }

    $Result = @()

    $WebResponse.Links `
    | Where-Object { $_.Href -match "https://wordpress.org/themes/" } `
    | Select-Object href, innerHTML, outerHTML `
    | ForEach-Object {
        $Result += @{
            "Path" = $_.href
            "Data" = $_.outerHTML
        }
    }


    Write-Output $Result

}

function Get-ThemePreviews() {

    $Result = @()

    $Result += Invoke-ThemeForestThemePreviews
    $Result += Invoke-TemplateMonsterThemePreviews
    $Result += Invoke-WordpressOrgThemePreviews

    Write-Output $Result | ConvertTo-Json

}

function Get-HtmlPreviews() {

    $Result = @()

    $Result += "<h1>Theme Previews</h1>"
    $Result += "<ul>"

    $ThemesJsonFile = $global:Path.FullName + [System.IO.Path]::DirectorySeparatorChar + "Themes.json"
    $ThemesJsonData = Get-Content -Path $ThemesJsonFile | ConvertFrom-Json

    foreach ($Preview in $ThemesJsonData) {
        $Result += "<li>"
        $Result += $Preview.Data
        $Result += "</li>"
    }

    $Result += "</ul>"

    Write-Output $Result

}

function Wrap-String() {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$String,
     
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [int]$Length
    )
    
    $Result = @()

    $String = $String -replace "`r`n", " "
    $String = $String -replace "`n", " "
    $String = $String -replace "`r", " "

    $Words = $String.Split(" ")

    $Line = ""

    foreach ($Word in $Words) {

        if ($Line.Length -gt 0) {
            $Line += " "
        }

        $Line += $Word

        if ($Line.Length -gt $Length) {
            $Result += $Line
            $Line = ""
        }
    }

    if ($Line.Length -gt 0) {
        $Result += $Line
    }

    $Result = $Result -join $Wrap

    Write-Output $Result

}

function ConvertTo-Markdown() {

    [CmdletBinding()]
    param (
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [string]
        $Html
    )

    # Load the contents of the file as a string 
    $content = Get-Content $Html | Join-String -Separator "`n"
    $content = "$content"
    
    # Convert Links from <a> to Markdown style
    $content = $content -replace '<a\s+href="([^"]+)">([^<]+)</a>', '[$2]($1)'

    # Convert paragraphs and lists
    $content = $content -replace "\s*<ul>\s*", "`r`n"
    $content = $content -replace "\s*</ul>\s*", "`r`n"
    $content = $content -replace "\s*<ol>\s*", "`r`n"
    $content = $content -replace "\s*</ol>\s*", "`r`n"
    $content = $content -replace "<p>", "`r`n"
    $content = $content -replace "</p>", "`r`n"
    $content = $content -replace "<li>", "`r`n  *  "
    $content = $content -replace "</li>", ""
    
    # Word wrap each paragraph
    $content = Wrap-String -String $content -Length 80
    
    # Word/Phrase highlighting    
    $content = $content -replace "<em>", "*"
    $content = $content -replace "</em>", "*"
    $content = $content -replace "<b>", "**"
    $content = $content -replace "</b>", "**"
    $content = $content -replace "<strong>", "**"
    $content = $content -replace "</strong>", "**"
    $content = $content -replace "&quot;", "'"
    
    $content = $content -replace "<!--break-->", ""
    
    # Eliminate excess whitespace
    $content = $content -replace "/^\s*$/", ""
    $content = $content -replace "`r`n`r`n`r`n", "`r`n`r`n"
    $content = $content -replace "`r`n`r`n`r`n", "`r`n`r`n"
    $content = $content -replace "`r`n`r`n`r`n", "`r`n`r`n"
    $content = $content -replace "`r`n`r`n`r`n", "`r`n`r`n"

    Write-Output $content 
}

function Stop-All() {

    docker-compose down

}

function Save-ThemePreviews() {

    $PathSeparator = [System.IO.Path]::DirectorySeparatorChar

    $JsonPath = $global:Path.FullName + $PathSeparator + "Themes.json"
    $HtmlPath = $global:Path.FullName + $PathSeparator + "Themes.html"
    
    Get-ThemePreviews | Out-File -FilePath $JsonPath -Encoding UTF8 -Force
    Get-HtmlPreviews | Out-File -FilePath $HtmlPath -Encoding UTF8 -Append

    $MarkdownPath = $global:Path.FullName + $PathSeparator + "Themes.md"
    ConvertTo-Markdown -Html $HtmlPath | Out-File -FilePath $MarkdownPath -Encoding UTF8 -Force

}

Install-PowershellModuleIfNotExists -ModuleName 'PowerShellGet'
Install-PowershellModuleIfNotExists -ModuleName 'QRCodeGenerator'
Install-PowershellModuleIfNotExists -ModuleName 'powershell-yaml'
# Invoke-WordPressLocal

function New-WordpressProject() {
    Stop-All
    Save-All
    Update-ImageTags
    Save-ThemePreviews
    Start-All
}

Export-ModuleMember -Function New-WordpressProject
