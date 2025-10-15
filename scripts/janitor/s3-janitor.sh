#!/usr/bin/env bash
set -e

echo -n ""

# Delete all object versions and delete markers before bucket deletion
empty_bucket_versions() {
  local bucket="$1"
  # Remove current versions fast
  aws s3 rm "s3://${bucket}" --recursive 2>/dev/null || true
  # Loop through pages of versions and delete-markers (up to 1000 per pass)
  while true; do
    # Count versions and delete markers on the first page
    local vcount mcount
    vcount=$(aws s3api list-object-versions --bucket "${bucket}" --query 'length(Versions)' --output text 2>/dev/null || echo 0)
    mcount=$(aws s3api list-object-versions --bucket "${bucket}" --query 'length(DeleteMarkers)' --output text 2>/dev/null || echo 0)
    [[ "${vcount}" == "None" || -z "${vcount}" ]] && vcount=0
    [[ "${mcount}" == "None" || -z "${mcount}" ]] && mcount=0

    # Nothing left to delete
    if (( vcount == 0 && mcount == 0 )); then
      break
    fi

    # Batch delete up to 1000 object versions
    if (( vcount > 0 )); then
      payload=$(aws s3api list-object-versions \
        --bucket "${bucket}" \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
        --output json)
      # delete-objects requires at least one object; guarded by vcount
      aws s3api delete-objects --bucket "${bucket}" --delete "${payload}" >/dev/null
    fi

    # Batch delete up to 1000 delete markers
    if (( mcount > 0 )); then
      payload=$(aws s3api list-object-versions \
        --bucket "${bucket}" \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
        --output json)
      aws s3api delete-objects --bucket "${bucket}" --delete "${payload}" >/dev/null
    fi
  done
}

# For S3 buckets: list and delete until none remain.
  while true; do
    buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null)
    if [[ -z "${buckets}" ]]; then
      break
    fi
    for bucket in ${buckets}; do
      empty_bucket_versions "${bucket}"
      aws s3api delete-bucket --bucket "${bucket}" 2>/dev/null || true
      echo -e "s3	bucket	${bucket}"
    done
  done
echo -n ""
