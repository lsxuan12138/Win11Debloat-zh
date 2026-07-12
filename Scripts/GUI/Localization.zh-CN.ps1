# Simplified Chinese UI localization. Keep this PowerShell 5.1 source ASCII-only.
$localizationPath = Join-Path $script:configPath 'Localization.zh-CN.json'
$localizationData = Get-Content -LiteralPath $localizationPath -Raw -Encoding UTF8 | ConvertFrom-Json
$featureLocalizationPath = Join-Path $script:configPath 'FeatureLabels.zh-CN.json'
$script:ZhCnFeatureLabels = Get-Content -LiteralPath $featureLocalizationPath -Raw -Encoding UTF8 | ConvertFrom-Json
$script:ZhCnUiText = @{}
foreach ($property in $localizationData.PSObject.Properties) {
    $script:ZhCnUiText[$property.Name] = [string]$property.Value
}

function Get-ZhCnUiText([string]$Text) {
    if ($null -ne $Text -and $script:ZhCnUiText.ContainsKey($Text)) { return $script:ZhCnUiText[$Text] }
    return $Text
}

function ConvertTo-ZhCnUi {
    param([Parameter(Mandatory)]$Root)
    if ($Root -is [System.Windows.Window]) { $Root.Title = Get-ZhCnUiText ([string]$Root.Title) }
    foreach ($property in @('Text', 'Content', 'Header', 'ToolTip')) {
        $descriptor = [System.ComponentModel.TypeDescriptor]::GetProperties($Root)[$property]
        if ($descriptor -and -not $descriptor.IsReadOnly) {
            $value = $descriptor.GetValue($Root)
            if ($value -is [string]) { $descriptor.SetValue($Root, (Get-ZhCnUiText $value)) }
        }
    }
    foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($Root)) {
        if ($child -is [System.Windows.DependencyObject]) { ConvertTo-ZhCnUi -Root $child }
    }
}

function ConvertTo-ZhCnFeatureConfig {
    param([Parameter(Mandatory)]$Config)
    foreach ($group in @($Config.UiGroups)) {
        $group.Label = Get-ZhCnUiText $group.Label
        if ($group.PSObject.Properties['ToolTip']) {
            $group.ToolTip = $group.Label
        }
        else {
            $group | Add-Member -MemberType NoteProperty -Name ToolTip -Value $group.Label
        }
        foreach ($value in @($group.Values)) { $value.Label = Get-ZhCnUiText $value.Label }
    }
    foreach ($feature in @($Config.Features)) { $feature.Label = Get-ZhCnUiText $feature.Label }
    foreach ($feature in @($Config.Features)) {
        $localized = $script:ZhCnFeatureLabels.($feature.FeatureId)
        if ($localized) {
            if ($localized.Label) { $feature.Label = $localized.Label }
            if ($localized.UndoLabel) { $feature.UndoLabel = $localized.UndoLabel }
            $localizedToolTip = if ($localized.ToolTip) { $localized.ToolTip } else { $localized.Label }
            if ($localizedToolTip) {
                if ($feature.PSObject.Properties['ToolTip']) {
                    $feature.ToolTip = $localizedToolTip
                }
                else {
                    $feature | Add-Member -MemberType NoteProperty -Name ToolTip -Value $localizedToolTip
                }
            }
        }
    }
    return $Config
}
