data "aws_iam_policy_document" "twilify_kms_key_policy" {
  statement {
    actions   = ["kms:*"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_kms_key" "twilify_kms_key" {
  deletion_window_in_days = 7
  enable_key_rotation = true
  policy = data.aws_iam_policy_document.twilify_kms_key_policy.json
}

resource "aws_kms_alias" "twilify_kms_alias" {
  name_prefix   = "alias/twilify-cmk-"
  target_key_id = aws_kms_key.twilify_kms_key.arn
}
