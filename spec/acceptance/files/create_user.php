#!/usr/bin/env php
<?php

$root = '/usr/local/src/phabricator';
require_once $root.'/scripts/__init_script__.php';

$username = 'test';
$realname = 'Mr Test';
$email    = 'fake@email.com';
$key_path = $argv[1];

$viewer = PhabricatorUser::getOmnipotentUser();
$source = new PhabricatorLipsumContentSource();

$user = id(new PhabricatorUser())
  ->setUsername($username);
  ->setRealname($realname);
  ->setIsApproved(1);

$email_object = id(new PhabricatorUserEmail())
  ->setAddress($email)
  ->setIsVerified(1);

id(new PhabricatorUserEditor())
  ->setActor($viewer)
  ->createNewUser($user, $email_object);

$key = PhabricatorAuthSSHKey::initializeNewSSHKey($user, $user);
list($public_key, $private_key) = PhabricatorSSHKeyGenerator::generateKeypair();
$public_key = PhabricatorAuthSSHPublicKey::newFromRawKey($public_key);

$xactions = array();

$xactions[] = id(new PhabricatorAuthSSHKeyTransaction())
  ->setTransactionType(PhabricatorTransactions::TYPE_CREATE);

$xactions[] = id(new PhabricatorAuthSSHKeyTransaction())
  ->setTransactionType(PhabricatorAuthSSHKeyTransaction::TYPE_NAME)
  ->setNewValue('id_rsa');

$xactions[] = id(new PhabricatorAuthSSHKeyTransaction())
  ->setTransactionType(PhabricatorAuthSSHKeyTransaction::TYPE_KEY)
  ->setNewValue($public_key->getType().' '.$public_key->getBody().' '.pht('Generated'));

id(new PhabricatorAuthSSHKeyEditor())
  ->setActor($viewer)
  ->setContentSource($source)
  ->applyTransactions($key, $xactions);

Filesystem::writeFile($key_path, $private_key);
Filesystem::changePermissions($key_path, 0400);
