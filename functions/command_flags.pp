function phabricator::command_flags(Hash[String, Data] $flags) >> String {
  $flags
    .filter |$key, $value| { $value != undef }
    .map |$key, $value| {
      case $value {
        false: { "--no-${key}" }
        true: { "--${key}" }
        default: { "--${key} ${value}" }
      }
    }
    .join(' ')
}